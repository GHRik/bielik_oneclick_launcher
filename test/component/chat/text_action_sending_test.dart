import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import '../../support/in_memory_chat_repository.dart';

void main() {
  late InMemoryChatRepository repository;
  late ChatWorkspace workspace;

  setUp(() async {
    repository = InMemoryChatRepository();
    workspace = ChatWorkspace(repository);
    await workspace.initialize();
  });

  tearDown(() async {
    await workspace.flush();
    workspace.dispose();
  });

  for (final action in ChatTextAction.values) {
    test(
      'The ${action.name} action sends the complete draft with its instruction',
      () async {
        final text = List.filled(
          100,
          'Ważna treść do przetworzenia.',
        ).join('\n');
        workspace.selected.draft.text = text;
        workspace.selected.offerTextActions();
        await workspace.sendTextAction(action);
        final messages = await repository.getMessages(workspace.selected.id);
        expect(messages.single.text, action.prompt(text));
        expect(messages.single.text, contains(text));
        expect(workspace.selected.offersTextActions, isFalse);
      },
    );
  }

  test('Typing alone does not offer text actions', () {
    workspace.selected.draft.text = 'Zwykłe pytanie';
    expect(workspace.selected.offersTextActions, isFalse);
  });

  test('Clearing imported text hides the actions', () {
    workspace.selected.draft.text = 'Tekst';
    workspace.selected.offerTextActions();
    workspace.selected.draft.clear();
    expect(workspace.selected.offersTextActions, isFalse);
  });

  test(
    'A failed save preserves the original draft for a clean retry',
    () async {
      workspace.selected.draft.text = 'Treść';
      workspace.selected.offerTextActions();
      repository.failSend = true;
      await workspace.sendTextAction(ChatTextAction.summarize);
      expect(workspace.selected.draft.text, 'Treść');
      repository.failSend = false;
      await workspace.sendTextAction(ChatTextAction.summarize);
      final messages = await repository.getMessages(workspace.selected.id);
      expect(messages.single.text, ChatTextAction.summarize.prompt('Treść'));
    },
  );

  test('Repeated taps while sending create only one message', () async {
    workspace.selected.draft.text = 'Treść';
    workspace.selected.offerTextActions();
    repository.sendGate = Completer<void>();
    final sending = workspace.sendTextAction(ChatTextAction.analyze);
    await workspace.sendTextAction(ChatTextAction.summarize);
    repository.sendGate!.complete();
    await sending;
    expect(await repository.getMessages(workspace.selected.id), hasLength(1));
  });
}
