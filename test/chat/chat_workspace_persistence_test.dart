import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import '../support/in_memory_chat_repository.dart';

void main() {
  group('Chat persistence failure recovery', () {
    Future<void> withWorkspace(
      WidgetTester tester,
      Future<void> Function(InMemoryChatRepository, ChatWorkspace) scenario,
    ) async {
      await tester.runAsync(() async {
        final repository = InMemoryChatRepository();
        final workspace = ChatWorkspace(repository);
        try {
          await scenario(repository, workspace);
        } finally {
          workspace.dispose();
          await workspace.flush();
        }
      });
      await tester.pump();
    }

    testWidgets('Reports an initialization failure without becoming ready', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, workspace) async {
        repository.failRead = true;

        await workspace.initialize();

        expect(workspace.ready, isFalse);
        expect(workspace.error, isNotNull);
      });
    });

    testWidgets('Can retry initialization after a read failure', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, workspace) async {
        repository.failRead = true;
        await workspace.initialize();
        repository.failRead = false;

        await workspace.initialize();

        expect(workspace.ready, isTrue);
        expect(workspace.error, isNull);
      });
    });

    testWidgets('Keeps the draft when saving a message fails', (tester) async {
      await withWorkspace(tester, (repository, workspace) async {
        await workspace.initialize();
        workspace.selected.draft.text = 'Keep this message';
        repository.failSend = true;

        await workspace.sendMessage(workspace.selected.draft.text);

        expect(workspace.selected.draft.text, 'Keep this message');
        expect(workspace.selected.controller.messages, isEmpty);
        expect(workspace.error, isNotNull);
        expect(workspace.sending, isFalse);
      });
    });

    testWidgets('Can send again after a storage failure', (tester) async {
      await withWorkspace(tester, (repository, workspace) async {
        await workspace.initialize();
        repository.failSend = true;
        await workspace.sendMessage('Question');
        repository.failSend = false;

        await workspace.sendMessage('Question');

        expect(workspace.selected.draft.text, '');
        expect(workspace.selected.controller.messages, hasLength(1));
        expect(workspace.error, isNull);
      });
    });

    testWidgets('Preserves a newer draft typed during a pending send', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, workspace) async {
        repository
          ..sendGate = Completer<void>()
          ..sendStarted = Completer<void>();
        await workspace.initialize();
        workspace.selected.draft.text = 'First message';
        final send = workspace.sendMessage('First message');
        await repository.sendStarted!.future;
        workspace.selected.draft.text = 'Next message';

        repository.sendGate!.complete();
        await send;
        await workspace.flush();

        expect(workspace.selected.draft.text, 'Next message');
        expect(
          (await repository.getConversations()).single.draft,
          'Next message',
        );
        expect(
          (await repository.getMessages(workspace.selected.id)).single.text,
          'First message',
        );
      });
    });

    testWidgets('Keeps the selected conversation when deletion fails', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, workspace) async {
        await workspace.initialize();
        final original = workspace.selected;
        repository.failDelete = true;

        await workspace.deleteConversation(original);

        expect(workspace.selected, same(original));
        expect(workspace.conversations, hasLength(1));
        expect(workspace.error, isNotNull);
      });
    });

    testWidgets(
      'Reports failure to create a replacement for the last deleted chat',
      (tester) async {
        await withWorkspace(tester, (repository, workspace) async {
          await workspace.initialize();
          repository.failCreate = true;

          await workspace.deleteConversation(workspace.selected);

          expect(workspace.ready, isFalse);
          expect(workspace.error, isNotNull);
        });
      },
    );

    testWidgets('Can retry after replacement chat creation fails', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, workspace) async {
        await workspace.initialize();
        final id = workspace.selected.id;
        repository.failCreate = true;
        await workspace.deleteConversation(workspace.selected);
        repository.failCreate = false;

        await workspace.initialize();

        expect(workspace.ready, isTrue);
        expect(workspace.selected.id, isNot(id));
        expect(await repository.getConversations(), hasLength(1));
      });
    });
  });

  testWidgets('Disposal finishes saving the latest pending draft', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository();
      final workspace = ChatWorkspace(repository);
      await workspace.initialize();
      workspace.selected.draft.text = 'Draft';
      workspace.selected.draft.text = 'Latest draft';

      workspace.dispose();
      await workspace.flush();

      expect(
        (await repository.getConversations()).single.draft,
        'Latest draft',
      );
    });
    await tester.pump();
  });
}
