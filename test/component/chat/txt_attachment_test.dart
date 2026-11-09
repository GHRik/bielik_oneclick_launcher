import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/text_attachment_page.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _Attachments implements AttachmentRepository {
  Future<void> Function()? onPick;
  TextAttachment? next = const TextAttachment(
    name: 'notatki.txt',
    text: 'Zażółć 🙂\nTreść do analizy',
    sizeBytes: 34,
  );
  AttachmentFailure? failure;
  @override
  Future<TextAttachment?> pickTextAttachment() async {
    await onPick?.call();
    if (failure != null) throw AttachmentException(failure!);
    return next;
  }
}

class _Llm implements LlmRepository {
  Completer<void>? loadGate;
  Object? loadFailure;
  bool rejectContext = false;
  int unloads = 0;
  final inputs = <List<ChatMessage>>[];
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
    await loadGate?.future;
    if (loadFailure != null) throw loadFailure!;
    if (rejectContext) throw ChatContextTooLong();
    await onPromptAccepted?.call();
    inputs.add(history);
    yield 'Odpowiedź';
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {
    unloads++;
  }
}

void main() {
  late _Attachments attachments;
  late _Llm llm;
  late InMemoryChatRepository chats;
  setUp(() {
    attachments = _Attachments();
    llm = _Llm();
    chats = InMemoryChatRepository();
  });

  Future<void> open(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MyApp(
        chatRepository: chats,
        modelFilesRepository: InMemoryModelFilesRepository(),
        attachmentRepository: attachments,
        llmRepository: llm,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Question');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'The message and attachment appear while the model is still loading',
    (tester) async {
      await open(tester);
      await pick(tester);
      llm.loadGate = Completer<void>();
      await tester.enterText(find.byType(TextField), 'Question');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Question'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.byKey(const ValueKey('pending-attachment')), findsNothing);
      expect(find.text('notatki.txt'), findsOneWidget);
      expect(llm.inputs, isEmpty);
      final conversation = (await chats.getConversations()).single;
      expect(await chats.getMessages(conversation.id), isEmpty);

      llm.loadGate!.complete();
      await tester.pumpAndSettle();
      expect(llm.inputs.single.last.text, 'Question');
      expect(
        (await chats.getMessages(conversation.id))
            .where((message) => message.role == ChatRole.user),
        hasLength(1),
      );
    },
  );

  testWidgets('A loading failure restores the question and its attachment', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    llm.loadGate = Completer<void>();
    llm.loadFailure = StateError('Loading failed');
    await tester.enterText(find.byType(TextField), 'Keep this');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    llm.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep this',
    );
    expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
    final conversation = (await chats.getConversations()).single;
    expect(await chats.getMessages(conversation.id), isEmpty);
    expect(conversation.draftAttachment?.name, 'notatki.txt');
  });

  testWidgets('Restoring a rejected send preserves a newer draft', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    llm.loadGate = Completer<void>();
    llm.loadFailure = StateError('Loading failed');
    await tester.enterText(find.byType(TextField), 'Original');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'New draft');

    llm.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Original\n\nNew draft',
    );
    expect(
      (await chats.getConversations()).single.draft,
      'Original\n\nNew draft',
    );
  });

  testWidgets(
    'A rejected summary keeps the attachment and original draft editable',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'Original request');
      await pick(tester);
      llm.rejectContext = true;

      await tester.tap(find.text('Streść'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Original request',
      );
      expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
      final conversation = (await chats.getConversations()).single;
      expect(await chats.getMessages(conversation.id), isEmpty);
    },
  );

  testWidgets('Adding a TXT does not display a context assessment', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);

    expect(find.textContaining('mieści się'), findsNothing);
    expect(find.textContaining('przekraczać kontekst'), findsNothing);
  });

  testWidgets('Adding a TXT file offers actions without sending', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    expect(find.text('Przetłumacz'), findsOneWidget);
    expect(find.text('Streść'), findsOneWidget);
    expect(find.text('Analizuj'), findsOneWidget);
    expect(llm.inputs, isEmpty);
  });

  testWidgets('Analyzing a file sends its complete text and instruction', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.text('Analizuj'));
    await tester.pumpAndSettle();
    final input = llm.inputs.single.last.text;
    expect(input, contains('Przeanalizuj'));
    expect(llm.inputs.single.last.attachment?.text, attachments.next!.text);
    expect(find.text('Analizuj'), findsNothing);
  });

  testWidgets('Removing a file hides actions for a typed-only draft', (
    tester,
  ) async {
    await open(tester);
    for (var length = 1; length <= 'Question'.length; length++) {
      await tester.enterText(
        find.byType(TextField),
        'Question'.substring(0, length),
      );
    }
    await pick(tester);
    await tester.tap(find.byTooltip('Usuń załącznik'));
    await tester.pumpAndSettle();
    expect(find.text('Analizuj'), findsNothing);
  });

  testWidgets('The system file picker does not unload the chat model', (
    tester,
  ) async {
    await open(tester);
    await send(tester);
    final unloads = llm.unloads;
    attachments.onPick = () async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.value();
      expect(llm.unloads, unloads);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    };
    await pick(tester);
    expect(llm.unloads, unloads);
    await send(tester);
    expect(llm.inputs, hasLength(2));
    expect(llm.unloads, unloads);
  });

  testWidgets('Pausing in the attachment preview keeps the chat model loaded', (
    tester,
  ) async {
    await open(tester);
    await send(tester);
    await pick(tester);
    final unloads = llm.unloads;
    await tester.tap(find.text('notatki.txt'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await Future<void>.value();
    expect(llm.unloads, unloads);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(llm.unloads, unloads);
  });

  testWidgets('Leaving the chat unloads its model after the idle timeout', (
    tester,
  ) async {
    await open(tester);
    await send(tester);
    final unloads = llm.unloads;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(llm.unloads, unloads);
    await tester.pump(const Duration(minutes: 2));
    await tester.pump();
    expect(llm.unloads, unloads + 1);
  });

  testWidgets('Opens the complete pending attachment in a selectable preview', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.text('notatki.txt'));
    await tester.pumpAndSettle();
    expect(find.byType(TextAttachmentPage), findsOneWidget);
    expect(find.text(attachments.next!.text), findsOneWidget);
    expect(find.byType(SelectionArea), findsWidgets);
    expect(llm.inputs, isEmpty);
  });

  testWidgets('Opens a sent attachment from its saved contents', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    final savedText = attachments.next!.text;
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    attachments.next = null;
    await tester.tap(find.text('notatki.txt'));
    await tester.pumpAndSettle();
    expect(find.byType(TextAttachmentPage), findsOneWidget);
    expect(find.text(savedText), findsOneWidget);
  });

  testWidgets('Removing an attachment does not open its preview', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.byTooltip('Usuń załącznik'));
    await tester.pumpAndSettle();
    expect(find.byType(TextAttachmentPage), findsNothing);
  });

  testWidgets('Closing the preview preserves the pending attachment', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.text('notatki.txt'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
  });

  testWidgets('Opens an attachment restored from conversation history', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    final savedText = attachments.next!.text;
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    attachments.next = null;
    await open(tester);
    await tester.tap(find.text('notatki.txt'));
    await tester.pumpAndSettle();
    expect(find.byType(TextAttachmentPage), findsOneWidget);
    expect(find.text(savedText), findsOneWidget);
  });

  testWidgets('The TXT preview shows formatting characters literally', (
    tester,
  ) async {
    attachments.next = const TextAttachment(
      name: 'literal.txt',
      text: '**Literal text**',
      sizeBytes: 16,
    );
    await open(tester);
    await pick(tester);
    await tester.tap(find.text('literal.txt'));
    await tester.pumpAndSettle();
    expect(find.text('**Literal text**'), findsOneWidget);
  });

  testWidgets('Picking TXT shows its name without invoking the model', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
    expect(find.text('notatki.txt'), findsOneWidget);
    expect(llm.inputs, isEmpty);
  });

  testWidgets('Sends the question together with the full attachment text', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.enterText(find.byType(TextField), 'Podsumuj plik');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(llm.inputs.single.single.text, 'Podsumuj plik');
    expect(llm.inputs.single.single.attachment!.text, attachments.next!.text);
    expect(find.byKey(const ValueKey('pending-attachment')), findsNothing);
  });

  testWidgets('Allows sending a TXT attachment without a typed question', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(llm.inputs, hasLength(1));
    expect(llm.inputs.single.single.attachment!.name, 'notatki.txt');
  });

  testWidgets('Removing a pending file also clears it in storage', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    await tester.tap(find.byTooltip('Usuń załącznik'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-attachment')), findsNothing);
    expect((await chats.getConversations()).single.draftAttachment, isNull);
  });

  testWidgets(
    'Cancelling a new file selection preserves the existing attachment',
    (tester) async {
      await open(tester);
      await pick(tester);
      attachments.next = null;
      await pick(tester);
      expect(find.text('notatki.txt'), findsOneWidget);
    },
  );

  testWidgets('A failed send keeps both the question and its attachment', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    chats.failSend = true;
    await tester.enterText(find.byType(TextField), 'Keep this');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep this',
    );
    expect(llm.inputs, isEmpty);
  });

  testWidgets('Shows a readable error for invalid TXT encoding', (
    tester,
  ) async {
    await open(tester);
    attachments.failure = AttachmentFailure.invalidEncoding;
    await pick(tester);
    expect(find.textContaining('UTF-8'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-attachment')), findsNothing);
  });

  testWidgets(
    'The pending attachment belongs to its originating conversation',
    (tester) async {
      await open(tester);
      await pick(tester);
      final workspace = tester
          .widget<ChatPage>(find.byType(ChatPage))
          .workspace;
      final original = workspace.selected;
      await workspace.newChat();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pending-attachment')), findsNothing);
      workspace.selectConversation(original);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pending-attachment')), findsOneWidget);
    },
  );

  testWidgets('Long attachment names fit on a narrow screen', (tester) async {
    attachments.next = TextAttachment(
      name: '${'long-name-' * 20}.txt',
      text: 'Content',
      sizeBytes: 7,
    );
    await open(tester, width: 320);
    await pick(tester);
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byKey(const ValueKey('pending-attachment'))).right,
      lessThanOrEqualTo(320),
    );
  });
}
