import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/system_clipboard_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';

import '../../support/in_memory_chat_repository.dart';

class _StreamingLlm implements LlmRepository {
  StreamController<String>? output;
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
    Future<void> Function()? onPromptAccepted,
  }) async* {
    output = StreamController<String>();
    await onPromptAccepted?.call();
    yield* output!.stream;
  }

  @override
  void stop() {
    final stream = output;
    if (stream != null && !stream.isClosed) unawaited(stream.close());
  }

  @override
  Future<void> unload() async {}
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); ++i) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late InMemoryChatRepository repository;
  late _StreamingLlm llm;
  late ChatWorkspace workspace;
  String? copied;

  setUp(() {
    repository = InMemoryChatRepository();
    llm = _StreamingLlm();
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> open(
    WidgetTester tester, {
    ClipboardRepository? clipboard,
  }) async {
    workspace = ChatWorkspace(repository, llmRepository: llm)
      ..useModel(bielikModels.first);
    await workspace.initialize();
    addTearDown(() async {
      final stopping = workspace.stopGeneration();
      await _pumpUntil(tester, () => !workspace.sending);
      await stopping;
      await tester.pumpWidget(const SizedBox.shrink());
      workspace.dispose();
      await tester.pump();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          workspace: workspace,
          statisticSeries: const [],
          clipboardRepository: clipboard,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startReply(WidgetTester tester) async {
    unawaited(workspace.sendMessage('Question'));
    await _pumpUntil(tester, () => llm.output != null);
    llm.output!.add('Odpowiedź');
    await _pumpUntil(tester, () => workspace.selected.messages.length >= 2);
  }

  testWidgets(
    'Copies the complete final reply including all streamed fragments',
    (tester) async {
      await open(tester, clipboard: const SystemClipboardRepository());
      await startReply(tester);
      const remainder = '\n\n**Cała odpowiedź** 🙂';
      llm.output!.add(remainder);
      await _pumpUntil(
        tester,
        () => workspace.selected.messages.last.text.endsWith(remainder),
      );
      unawaited(llm.output!.close());
      await _pumpUntil(tester, () => !workspace.sending);
      await tester.pumpAndSettle();
      final answer = workspace.selected.messages.last;
      await tester.tap(find.byKey(ValueKey('copy-message-${answer.id}')));
      await tester.pumpAndSettle();
      expect(copied, 'Odpowiedź$remainder');
    },
  );

  testWidgets('Copies the saved partial reply after a manual stop', (
    tester,
  ) async {
    await open(tester, clipboard: const SystemClipboardRepository());
    await startReply(tester);
    final stopping = workspace.stopGeneration();
    await _pumpUntil(tester, () => !workspace.sending);
    await stopping;
    await tester.pumpAndSettle();
    final answer = workspace.selected.messages.last;
    await tester.tap(find.byKey(ValueKey('copy-message-${answer.id}')));
    await tester.pumpAndSettle();
    expect(copied, 'Odpowiedź');
  });

  testWidgets('Copies an earlier answer while the next answer is streaming', (
    tester,
  ) async {
    await open(tester, clipboard: const SystemClipboardRepository());
    await startReply(tester);
    final old = workspace.selected.messages.last;
    unawaited(llm.output!.close());
    await _pumpUntil(tester, () => !workspace.sending);
    llm.output = null;
    unawaited(workspace.sendMessage('Next'));
    await _pumpUntil(tester, () => llm.output != null);
    llm.output!.add('Another reply');
    await _pumpUntil(tester, () => workspace.selected.messages.length == 4);
    final button = find.byKey(ValueKey('copy-message-${old.id}'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied, 'Odpowiedź');
  });

  testWidgets('Hides the answer copy action during streaming', (tester) async {
    await open(tester);
    await startReply(tester);
    final answer = workspace.selected.messages.last;
    expect(find.byKey(ValueKey('copy-message-${answer.id}')), findsNothing);
    expect(
      find.byKey(
        ValueKey('copy-message-${workspace.selected.messages.first.id}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Shows the answer copy action after generation finishes', (
    tester,
  ) async {
    await open(tester);
    await startReply(tester);
    final answer = workspace.selected.messages.last;
    unawaited(llm.output!.close());
    await _pumpUntil(tester, () => !workspace.sending);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('copy-message-${answer.id}')), findsOneWidget);
  });

  testWidgets('Shows copy for a partial answer after stopping generation', (
    tester,
  ) async {
    await open(tester);
    await startReply(tester);
    final answer = workspace.selected.messages.last;
    final stopping = workspace.stopGeneration();
    await _pumpUntil(tester, () => !workspace.sending);
    await stopping;
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('copy-message-${answer.id}')), findsOneWidget);
  });

  testWidgets('An older answer stays copyable during the next generation', (
    tester,
  ) async {
    await open(tester);
    await startReply(tester);
    final old = workspace.selected.messages.last;
    unawaited(llm.output!.close());
    await _pumpUntil(tester, () => !workspace.sending);
    llm.output = null;
    unawaited(workspace.sendMessage('Next question'));
    await _pumpUntil(tester, () => llm.output != null);
    llm.output!.add('Nowa odpowiedź');
    await _pumpUntil(tester, () => workspace.selected.messages.length == 4);
    expect(find.byKey(ValueKey('copy-message-${old.id}')), findsOneWidget);
    final current = workspace.selected.messages.last;
    expect(find.byKey(ValueKey('copy-message-${current.id}')), findsNothing);
  });
}
