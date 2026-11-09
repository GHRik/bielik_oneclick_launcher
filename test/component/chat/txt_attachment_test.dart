import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/attachment_preview.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _Attachments implements AttachmentRepository {
  TextAttachment? next = const TextAttachment(
    name: 'notatki.txt',
    text: 'Zażółć 🙂\nTreść do analizy',
    sizeBytes: 34,
  );
  AttachmentFailure? failure;
  @override
  Future<TextAttachment?> pickTextAttachment() async {
    if (failure != null) throw AttachmentException(failure!);
    return next;
  }
}

class _Llm implements LlmRepository {
  final inputs = <List<ChatMessage>>[];
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
  }) {
    inputs.add(history);
    return Stream.value('Odpowiedź');
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {}
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

  testWidgets('Picking TXT shows its name without invoking the model', (
    tester,
  ) async {
    await open(tester);
    await pick(tester);
    expect(find.byType(AttachmentPreview), findsOneWidget);
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
    expect(find.byType(AttachmentPreview), findsNothing);
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
    expect(find.byType(AttachmentPreview), findsNothing);
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
    expect(find.byType(AttachmentPreview), findsOneWidget);
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
    expect(find.byType(AttachmentPreview), findsNothing);
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
      expect(find.byType(AttachmentPreview), findsNothing);
      workspace.selectConversation(original);
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentPreview), findsOneWidget);
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
      tester.getRect(find.byType(AttachmentPreview)).right,
      lessThanOrEqualTo(320),
    );
  });
}
