import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import 'support/in_memory_chat_repository.dart';

void main() {
  testWidgets('Load retry and failed sends preserve the draft', (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository()..failRead = true;
      final workspace = ChatWorkspace(repository);
      await workspace.initialize();
      expect(workspace.ready, isFalse);
      expect(workspace.error, isNotNull);
      repository.failRead = false;
      await workspace.initialize();
      expect(workspace.ready, isTrue);
      expect(workspace.error, isNull);
      workspace.selected.draft.text = 'Nie zgub tej wiadomości';
      repository.failSend = true;
      await workspace.sendMessage(workspace.selected.draft.text);
      expect(workspace.selected.draft.text, 'Nie zgub tej wiadomości');
      expect(workspace.selected.controller.messages, isEmpty);
      expect(workspace.error, isNotNull);
      expect(workspace.sending, isFalse);
      repository.failSend = false;
      await workspace.sendMessage(workspace.selected.draft.text);
      expect(workspace.selected.draft.text, '');
      expect(workspace.selected.controller.messages, hasLength(1));
      expect(workspace.error, isNull);
      workspace.dispose();
      await workspace.flush();
    });
    await tester.pump();
  });

  testWidgets('Typing during a pending send preserves the newer draft',
      (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository()
        ..sendGate = Completer<void>()
        ..sendStarted = Completer<void>();
      final workspace = ChatWorkspace(repository);
      await workspace.initialize();
      workspace.selected.draft.text = 'Pierwsza wiadomość';
      final pendingSend = workspace.sendMessage('Pierwsza wiadomość');
      await repository.sendStarted!.future;
      workspace.selected.draft.text = 'Następna wiadomość w trakcie pisania';
      repository.sendGate!.complete();
      await pendingSend;
      await workspace.flush();
      expect(workspace.selected.draft.text, 'Następna wiadomość w trakcie pisania');
      expect(
        (await repository.getConversations()).single.draft,
        'Następna wiadomość w trakcie pisania',
      );
      expect((await repository.getMessages(workspace.selected.id)).single.text,
          'Pierwsza wiadomość');
      workspace.dispose();
      await workspace.flush();
    });
    await tester.pump();
  });

  testWidgets('Deletion failures keep the chat and empty-history retry works',
      (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository();
      final workspace = ChatWorkspace(repository);
      await workspace.initialize();
      final original = workspace.selected;
      repository.failDelete = true;
      await workspace.deleteConversation(original);
      expect(workspace.selected, same(original));
      expect(workspace.conversations, hasLength(1));
      expect(workspace.error, isNotNull);

      repository
        ..failDelete = false
        ..failCreate = true;
      await workspace.deleteConversation(original);
      expect(workspace.ready, isFalse);
      expect(workspace.error, isNotNull);
      repository.failCreate = false;
      await workspace.initialize();
      expect(workspace.ready, isTrue);
      expect(workspace.selected.id, isNot(original.id));
      expect(await repository.getConversations(), hasLength(1));
      workspace.dispose();
      await workspace.flush();
    });
    await tester.pump();
  });

  testWidgets('Disposal lets the latest pending draft finish saving',
      (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository();
      final workspace = ChatWorkspace(repository);
      await workspace.initialize();
      workspace.selected.draft.text = 'Szkic';
      workspace.selected.draft.text = 'Ostatnia wersja szkicu';
      workspace.dispose();
      await workspace.flush();
      expect((await repository.getConversations()).single.draft,
          'Ostatnia wersja szkicu');
    });
    await tester.pump();
  });
}
