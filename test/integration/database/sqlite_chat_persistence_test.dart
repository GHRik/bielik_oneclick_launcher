import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late AppDatabase database;
  late SqliteChatRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bielik-chat-test-');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, AppDatabase.fileName),
    );
    repository = SqliteChatRepository(SqliteChatDataSource(database));
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<void> reopen() async {
    await database.close();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, AppDatabase.fileName),
    );
    repository = SqliteChatRepository(SqliteChatDataSource(database));
  }

  group('SQLite chat repository persistence', () {
    test('Persists recently used conversations first', () async {
      final first = await repository.createConversation();
      await repository.createConversation();
      await repository.markConversationUsed(first.id);
      await reopen();
      expect((await repository.getConversations()).first.id, first.id);
    });

    test('Saving a background draft does not change usage order', () async {
      final first = await repository.createConversation();
      final second = await repository.createConversation();
      await repository.saveDraft(first.id, 'Background draft');
      expect((await repository.getConversations()).first.id, second.id);
    });

    test('Rapid selections preserve their final order', () async {
      final first = await repository.createConversation();
      final second = await repository.createConversation();
      await repository.markConversationUsed(first.id);
      await repository.markConversationUsed(second.id);
      await repository.markConversationUsed(first.id);
      expect((await repository.getConversations()).map((chat) => chat.id), [
        first.id,
        second.id,
      ]);
    });

    test(
      'Returns conversations with stable IDs in newest-first order',
      () async {
        final first = await repository.createConversation();
        final second = await repository.createConversation();

        await reopen();

        expect((await repository.getConversations()).map((c) => c.id), [
          second.id,
          first.id,
        ]);
      },
    );

    test(
      'Persists a conversation title assigned when sending a message',
      () async {
        final chat = await repository.createConversation();
        await repository.addMessage(
          conversationId: chat.id,
          authorId: 'local-user',
          text: 'Hello 👋',
          conversationTitle: 'First conversation',
        );

        await reopen();

        expect(
          (await repository.getConversations()).single.title,
          'First conversation',
        );
      },
    );

    test('Preserves a Unicode draft after reopening', () async {
      final chat = await repository.createConversation();
      await repository.saveDraft(chat.id, 'Szkic po polsku: ąęł');

      await reopen();

      expect(
        (await repository.getConversations()).single.draft,
        'Szkic po polsku: ąęł',
      );
    });

    test('Preserves message identity and text after reopening', () async {
      final chat = await repository.createConversation();
      final message = await repository.addMessage(
        conversationId: chat.id,
        authorId: 'local-user',
        text: 'Hello 👋',
      );

      await reopen();

      final restored = (await repository.getMessages(chat.id)).single;
      expect(restored.id, message.id);
      expect(restored.text, 'Hello 👋');
    });

    test('Allocates unique message IDs after reopening', () async {
      final chat = await repository.createConversation();
      final first = await repository.addMessage(
        conversationId: chat.id,
        authorId: 'local-user',
        text: 'First',
      );
      await reopen();

      final next = await repository.addMessage(
        conversationId: chat.id,
        authorId: 'local-user',
        text: 'Next',
      );

      expect(next.id, isNot(first.id));
      expect((await repository.getMessages(chat.id)).map((m) => m.text), [
        'First',
        'Next',
      ]);
    });

    test('Clears the draft when requested by a message submission', () async {
      final chat = await repository.createConversation();
      await repository.saveDraft(chat.id, 'Draft');

      await repository.addMessage(
        conversationId: chat.id,
        authorId: 'local-user',
        text: 'Sent',
        clearDraft: true,
      );

      expect((await repository.getConversations()).single.draft, '');
    });

    test('Deletion persists without deleting other conversations', () async {
      final first = await repository.createConversation();
      final second = await repository.createConversation();

      await repository.deleteConversation(first.id);
      await reopen();

      expect((await repository.getConversations()).single.id, second.id);
    });

    test(
      'Deleting a conversation also removes its messages after reopening',
      () async {
        final chat = await repository.createConversation();
        await repository.addMessage(
          conversationId: chat.id,
          authorId: 'local-user',
          text: 'Message',
        );

        await repository.deleteConversation(chat.id);
        await reopen();

        expect(await repository.getMessages(chat.id), isEmpty);
      },
    );

    test(
      'Persists an updated assistant response without changing its identity',
      () async {
        final chat = await repository.createConversation();
        final assistant = await repository.addMessage(
          conversationId: chat.id,
          authorId: 'bielik',
          text: 'First',
        );
        await repository.updateMessage(assistant.id, 'First and second');

        await reopen();

        final restored = (await repository.getMessages(chat.id)).single;
        expect(restored.id, assistant.id);
        expect(restored.authorId, 'bielik');
        expect(restored.text, 'First and second');
      },
    );

    test(
      'Updating an assistant response preserves the next user draft',
      () async {
        final chat = await repository.createConversation();
        await repository.saveDraft(chat.id, 'Next question');
        final assistant = await repository.addMessage(
          conversationId: chat.id,
          authorId: 'bielik',
          text: 'First',
        );

        await repository.updateMessage(assistant.id, 'Complete');
        await reopen();

        expect(
          (await repository.getConversations()).single.draft,
          'Next question',
        );
      },
    );
  });

  group('Workspace restoration from SQLite', () {
    Future<void> withRestoredWorkspace(
      WidgetTester tester,
      Future<void> Function(ChatWorkspace, int, int, int, int) scenario,
    ) async {
      await tester.runAsync(() async {
        final workspace = ChatWorkspace(repository);
        await workspace.initialize();
        final firstId = workspace.selected.id;
        await workspace.sendMessage('Persistent message');
        final firstSize = workspace.selected.contentSizeBytes;
        await workspace.newChat();
        final secondId = workspace.selected.id;
        workspace.selected.draft.text = 'Second draft';
        final secondSize = workspace.selected.contentSizeBytes;
        workspace.dispose();
        await workspace.flush();
        await reopen();
        final restored = ChatWorkspace(repository);
        await restored.initialize();
        try {
          await scenario(restored, firstId, secondId, firstSize, secondSize);
        } finally {
          restored.dispose();
          await restored.flush();
        }
      });
      await tester.pump();
    }

    testWidgets('Restores conversation order and the newest draft', (
      tester,
    ) async {
      await withRestoredWorkspace(tester, (
        restored,
        firstId,
        secondId,
        firstSize,
        secondSize,
      ) async {
        expect(restored.error, isNull);
        expect(restored.conversations.map((c) => c.id), [secondId, firstId]);
        expect(restored.selected.draft.text, 'Second draft');
      });
    });

    testWidgets('Restores messages and the title of an older conversation', (
      tester,
    ) async {
      await withRestoredWorkspace(tester, (
        restored,
        firstId,
        secondId,
        firstSize,
        secondSize,
      ) async {
        restored.selectConversation(restored.conversations.last);

        expect(
          restored.selected.controller.messages.whereType<TextMessage>().map(
            (m) => m.text,
          ),
          ['Persistent message'],
        );
        expect(restored.selected.title, 'Persistent message');
      });
    });

    testWidgets('Recalculates conversation sizes from restored content', (
      tester,
    ) async {
      await withRestoredWorkspace(tester, (
        restored,
        firstId,
        secondId,
        firstSize,
        secondSize,
      ) async {
        expect(restored.selected.contentSizeBytes, secondSize);
        restored.selectConversation(restored.conversations.last);
        expect(restored.selected.contentSizeBytes, firstSize);
      });
    });

    testWidgets('Can send another message after restoring a conversation', (
      tester,
    ) async {
      await withRestoredWorkspace(tester, (
        restored,
        firstId,
        secondId,
        firstSize,
        secondSize,
      ) async {
        restored.selectConversation(restored.conversations.last);
        restored.selected.draft.text = 'After restart';

        await restored.sendMessage('After restart');

        expect(restored.selected.draft.text, '');
        expect((await repository.getMessages(firstId)).map((m) => m.text), [
          'Persistent message',
          'After restart',
        ]);
      });
    });

    testWidgets(
      'Deleting the selected chat selects the remaining conversation',
      (tester) async {
        await withRestoredWorkspace(tester, (
          restored,
          firstId,
          secondId,
          firstSize,
          secondSize,
        ) async {
          restored.selectConversation(restored.conversations.last);

          await restored.deleteConversation(restored.selected);

          expect(restored.selected.id, secondId);
        });
      },
    );

    testWidgets('Deleting every chat persists a new empty replacement', (
      tester,
    ) async {
      await withRestoredWorkspace(tester, (
        restored,
        firstId,
        secondId,
        firstSize,
        secondSize,
      ) async {
        await restored.deleteConversation(restored.conversations.last);
        await restored.deleteConversation(restored.selected);
        await restored.flush();

        expect(restored.conversations, hasLength(1));
        expect(restored.selected.id, isNot(anyOf(firstId, secondId)));
        await reopen();
        expect(await repository.getMessages(firstId), isEmpty);
        expect((await repository.getConversations()).single.draft, '');
      });
    });
  });
}
