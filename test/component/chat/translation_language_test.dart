import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

void main() {
  late InMemoryChatRepository repository;
  late ChatWorkspace workspace;
  const source = 'Ala ma kota.';

  Future<void> open(
    WidgetTester tester, {
    String draft = source,
    TextAttachment? attachment,
  }) async {
    repository = InMemoryChatRepository();
    await tester.pumpWidget(
      MyApp(
        chatRepository: repository,
        modelFilesRepository: InMemoryModelFilesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    workspace = tester.widget<ChatPage>(find.byType(ChatPage)).workspace;
    workspace.selected.draft.text = draft;
    workspace.selected.offerTextActions();
    if (attachment != null) workspace.selected.setAttachment(attachment);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Przetłumacz'));
    await tester.pumpAndSettle();
  }

  testWidgets('Translate waits for a language selection before sending', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Na jaki język przetłumaczyć?'), findsOneWidget);
    expect(await repository.getMessages(workspace.selected.id), isEmpty);
    expect(workspace.selected.draft.text, source);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
  });

  for (final language in TranslationLanguage.values) {
    testWidgets('Choosing ${language.label} sends that target language', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text(language.label));
      await tester.pumpAndSettle();
      final messages = await repository.getMessages(workspace.selected.id);
      expect(messages.single.text, contains('na język ${language.promptName}'));
      expect(messages.single.text, contains(source));
      expect(workspace.selected.draft.text, isEmpty);
    });
  }

  testWidgets('Cancelling keeps the TXT and draft editable', (tester) async {
    const attachment = TextAttachment(
      name: 'notes.txt',
      text: 'Source text.',
      sizeBytes: 12,
    );
    await open(tester, attachment: attachment);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(workspace.selected.draft.text, source);
    expect(workspace.selected.attachment, attachment);
    expect(await repository.getMessages(workspace.selected.id), isEmpty);
  });

  testWidgets('Translating a TXT places the task after its contents', (
    tester,
  ) async {
    const attachment = TextAttachment(
      name: 'notes.txt',
      text: 'Treść pliku.',
      sizeBytes: 12,
    );
    await open(tester, draft: '', attachment: attachment);
    await tester.tap(find.text('Angielski'));
    await tester.pumpAndSettle();
    final message = (await repository.getMessages(workspace.selected.id))
        .single;
    expect(message.attachment, attachment);
    expect(
      message.promptText.indexOf('Zadanie:'),
      greaterThan(message.promptText.indexOf(attachment.text)),
    );
    expect(message.promptText, contains('na język angielski'));
  });

  testWidgets(
    'A changed draft is not sent using a stale translation selection',
    (tester) async {
      await open(tester);
      workspace.selected.draft.text = 'Nowa treść';
      await tester.tap(find.text('Angielski'));
      await tester.pumpAndSettle();
      expect(await repository.getMessages(workspace.selected.id), isEmpty);
      expect(workspace.selected.draft.text, 'Nowa treść');
    },
  );
}
