import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/database_configuration.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/configuration/system_prompt.dart';
import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';

const e2ePackage = 'bielik.ai.bielik_oneclick_launcher.e2e';
const e2ePhase = String.fromEnvironment('E2E_PHASE');
const e2eRunId = String.fromEnvironment('E2E_RUN_ID');
const downloadTimeout = Duration(minutes: 30);
const generationTimeout = Duration(minutes: 10);

String get conversationPrompt =>
    'E2E ${e2eRunId.length > 12 ? e2eRunId.substring(e2eRunId.length - 12) : e2eRunId}. Napisz OK.';

class E2eApplication {
  E2eApplication._(
    this.database,
    this.chats,
    this.files,
    this.llm,
    this.models,
  );
  final AppDatabase database;
  final SqliteChatRepository chats;
  final ModelFileDataSource files;
  final LocalLlmRepository llm;
  final LocalModelFilesRepository models;

  static Future<E2eApplication> start(WidgetTester tester) async {
    if (!Platform.isAndroid || !const bool.fromEnvironment('BIELIK_E2E')) {
      throw StateError(
        'E2E requires Android and --dart-define=BIELIK_E2E=true.',
      );
    }
    final support = await getApplicationSupportDirectory();
    if (!support.path.split('/').contains(e2ePackage)) {
      throw StateError(
        'Refusing to test against the production application sandbox.',
      );
    }
    await FlutterModelDownloadDataSource.initialize();
    final database = await createAppDatabase();
    final files = ModelFileDataSource();
    final chats = SqliteChatRepository(SqliteChatDataSource(database));
    final models = LocalModelFilesRepository(files);
    final profile = defaultLlmConfiguration.copyWith(
      contextSize: 512,
      responseTokens: 32,
      numberOfThreads: 2,
      batchSize: 64,
      temperature: 0,
    );
    final llm = LocalLlmRepository(
      files,
      configurationFor: (_) => profile,
      systemPrompt: bielikSystemPrompt,
    );
    final app = E2eApplication._(database, chats, files, llm, models);
    await tester.pumpWidget(
      MyApp(
        chatRepository: chats,
        modelFilesRepository: models,
        llmRepository: llm,
        llmConfiguration: profile,
        deviceResourcesRepository: const LocalDeviceResourcesRepository(
          DeviceResourcesDataSource(),
        ),
      ),
    );
    await waitFor(
      tester,
      () => find.text('Otwórz czat').evaluate().isNotEmpty,
      description: 'home screen',
    );
    return app;
  }

  Future<void> close(WidgetTester tester) async {
    final pages = find.byType(ChatPage).evaluate();
    if (pages.isNotEmpty) {
      final workspace = (pages.first.widget as ChatPage).workspace;
      await workspace.releaseModel();
      await workspace.flush();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await llm.unload();
    await database.close();
  }

  Future<void> verifyModel() async {
    final model = bielikModels.first.file!;
    final file = await files.file(model);
    expect(await file.exists(), isTrue, reason: 'Downloaded GGUF must exist.');
    expect(await file.length(), model.sizeBytes);
    expect((await sha256.bind(file.openRead()).first).toString(), model.sha256);
  }

  Future<void> downloadModel(
    WidgetTester tester, {
    bool requireTransfer = false,
  }) async {
    final model = bielikModels.first.file!;
    if (await models.isDownloaded(model)) {
      if (requireTransfer) {
        await deleteModel(tester);
      } else {
        await verifyModel();
        return;
      }
    }
    final download = find.widgetWithText(FilledButton, 'Pobierz');
    await waitFor(
      tester,
      () =>
          download.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(download).onPressed != null,
      description: 'enabled download button',
    );
    await tester.ensureVisible(download);
    await tester.tap(download);
    await waitFor(
      tester,
      () =>
          find.text('Pobierz mimo to').evaluate().isNotEmpty ||
          find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
          find.text('Pobrano').evaluate().isNotEmpty,
      description: 'download start or confirmation',
    );
    final confirm = find.text('Pobierz mimo to');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
    }
    await waitFor(
      tester,
      () {
        final controllers = tester
            .widgetList<ListenableBuilder>(find.byType(ListenableBuilder))
            .map((w) => w.listenable)
            .whereType<ModelDownloadController>();
        for (final controller in controllers) {
          if (controller.error != null) throw TestFailure(controller.error!);
        }
        return find.text('Pobrano').evaluate().isNotEmpty;
      },
      description: 'completed and verified model download',
      timeout: downloadTimeout,
    );
    await verifyModel();
  }

  Future<void> deleteModel(WidgetTester tester) async {
    final button = find.widgetWithText(OutlinedButton, 'Usuń');
    await waitFor(
      tester,
      () =>
          button.evaluate().isNotEmpty &&
          tester.widget<OutlinedButton>(button).onPressed != null,
      description: 'enabled model delete button',
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await waitFor(
      tester,
      () => find.text('Usunąć model?').evaluate().isNotEmpty,
      description: 'model deletion confirmation',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await waitFor(
      tester,
      () =>
          find.text('Pobierz').evaluate().isNotEmpty &&
          tester.widget<OutlinedButton>(button).onPressed == null,
      description: 'model removed',
    );
    final file = await files.file(bielikModels.first.file!);
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.part').exists(), isFalse);
    expect(await models.hasPendingDownload(bielikModels.first.file!), isFalse);
  }
}

Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready, {
  required String description,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    final error = tester.takeException();
    if (error != null) {
      throw TestFailure('Flutter error while waiting for $description: $error');
    }
    if (watch.elapsed > timeout) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump();
}

Future<ChatWorkspace> openChat(WidgetTester tester) async {
  await tester.tap(find.text('Otwórz czat'));
  await waitFor(
    tester,
    () =>
        find.byType(ChatPage).evaluate().isNotEmpty &&
        tester.widget<ChatPage>(find.byType(ChatPage)).workspace.ready,
    description: 'loaded chat history',
  );
  return tester.widget<ChatPage>(find.byType(ChatPage)).workspace;
}

Future<void> openSidebar(WidgetTester tester) async {
  final menu = find.byTooltip('Rozmowy');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await waitFor(
      tester,
      () => find.text('New chat').hitTestable().evaluate().isNotEmpty,
      description: 'conversation sidebar',
    );
  }
}

Future<void> newChat(WidgetTester tester) async {
  final workspace = tester.widget<ChatPage>(find.byType(ChatPage)).workspace;
  final previousId = workspace.selected.id;
  await openSidebar(tester);
  await tester.tap(find.text('New chat'));
  await waitFor(
    tester,
    () =>
        workspace.selected.id != previousId &&
        !workspace.busy &&
        find.byType(TextField).hitTestable().evaluate().isNotEmpty,
    description: 'new conversation',
  );
}

Future<String> sendAndGenerate(
  WidgetTester tester,
  ChatWorkspace workspace,
  String prompt,
) async {
  await tester.enterText(find.byType(TextField), prompt);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send));
  await waitFor(
    tester,
    () =>
        workspace.sending ||
        workspace.selected.messages.any((m) => m.text == prompt),
    description: 'submitted user message',
  );
  await waitFor(
    tester,
    () {
      if (workspace.error != null) throw TestFailure(workspace.error!);
      return !workspace.sending &&
          workspace.selected.messages.any(
            (m) => m.role == ChatRole.assistant && m.text.trim().isNotEmpty,
          );
    },
    description: 'real CPU response',
    timeout: generationTimeout,
  );
  expect(workspace.error, isNull);
  expect(workspace.runtimeInfo?.mode, LlmComputeMode.cpu);
  final reply = workspace.selected.messages
      .lastWhere((m) => m.role == ChatRole.assistant)
      .text;
  expect(reply.trim(), isNotEmpty);
  expect(
    reply,
    isNot(contains('\uFFFD')),
    reason: 'Response must not contain broken UTF-8.',
  );
  expect(find.text(reply, findRichText: true), findsWidgets);
  await workspace.flush();
  return reply;
}

Future<void> deleteConversation(
  WidgetTester tester,
  E2eApplication app,
  ChatWorkspace workspace,
) async {
  final id = workspace.selected.id;
  final title = workspace.selected.title;
  await openSidebar(tester);
  final bin = find.byTooltip('Usuń rozmowę: $title');
  await tester.tap(bin);
  await waitFor(
    tester,
    () => find.byType(AlertDialog).evaluate().isNotEmpty,
    description: 'conversation deletion confirmation',
  );
  expect((await app.chats.getConversations()).any((c) => c.id == id), isTrue);
  await tester.tap(find.text('Anuluj'));
  await waitFor(
    tester,
    () => find.byType(AlertDialog).evaluate().isEmpty,
    description: 'cancelled deletion',
  );
  expect((await app.chats.getConversations()).any((c) => c.id == id), isTrue);
  await tester.tap(bin);
  await waitFor(
    tester,
    () => find.byType(AlertDialog).evaluate().isNotEmpty,
    description: 'second deletion confirmation',
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
  await waitFor(
    tester,
    () => !workspace.busy && !workspace.conversations.any((c) => c.id == id),
    description: 'deleted conversation',
  );
  await workspace.flush();
  expect((await app.chats.getConversations()).any((c) => c.id == id), isFalse);
  expect(await app.chats.getMessages(id), isEmpty);
}

void androidScenario(
  String name,
  Future<void> Function(WidgetTester, E2eApplication) body, {
  Duration timeout = const Duration(minutes: 45),
}) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(name, (tester) async {
    final watch = Stopwatch()..start();
    E2eApplication? app;
    final result = <String, dynamic>{
      'scenario': name,
      'phase': e2ePhase,
      'runId': e2eRunId,
      'pid': pid,
      'model': bielikModels.first.file!.name,
      'compute': 'cpu',
      'status': 'running',
    };
    binding.reportData = result;
    try {
      if (!RegExp(r'^[0-9]{10,32}$').hasMatch(e2eRunId)) {
        throw StateError(
          'E2E_RUN_ID must be a numeric timestamp set by the host runner.',
        );
      }
      app = await E2eApplication.start(tester);
      await body(tester, app);
      result['status'] = 'passed';
    } catch (error, stack) {
      result['status'] = 'failed';
      result['error'] = '$error';
      result['stack'] = '$stack';
      try {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
        await binding.takeScreenshot('$e2ePhase-failure');
      } catch (screenshotError) {
        result['screenshotError'] = '$screenshotError';
      }
      rethrow;
    } finally {
      result['durationMs'] = watch.elapsedMilliseconds;
      binding.reportData = result;
      if (app != null) {
        try {
          await app.close(tester);
        } catch (error) {
          result['status'] = 'failed';
          result['cleanupError'] = '$error';
          binding.reportData = result;
          rethrow;
        }
      }
    }
  }, timeout: Timeout(timeout));
}
