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

  test('Persists titles, messages and drafts with stable unique IDs', () async {
    final first = await repository.createConversation();
    final second = await repository.createConversation();
    final message = await repository.addMessage(
      conversationId: first.id,
      authorId: 'local-user',
      text: 'Cześć 👋',
      conversationTitle: 'Pierwsza rozmowa',
    );
    await repository.saveDraft(first.id, 'Szkic po polsku: ąęł');
    await reopen();

    final conversations = await repository.getConversations();
    expect(conversations.map((chat) => chat.id), [second.id, first.id]);
    expect(conversations.last.title, 'Pierwsza rozmowa');
    expect(conversations.last.draft, 'Szkic po polsku: ąęł');
    expect((await repository.getMessages(first.id)).single.id, message.id);

    final next = await repository.addMessage(
      conversationId: first.id,
      authorId: 'local-user',
      text: 'Kolejna wiadomość',
      clearDraft: true,
    );
    expect(next.id, isNot(message.id));
    expect((await repository.getMessages(first.id)).map((item) => item.text), [
      'Cześć 👋',
      'Kolejna wiadomość',
    ]);
    expect(
      (await repository.getConversations())
          .singleWhere((chat) => chat.id == first.id)
          .draft,
      '',
    );

    await repository.deleteConversation(first.id);
    await reopen();
    expect((await repository.getConversations()).single.id, second.id);
    expect(await repository.getMessages(first.id), isEmpty);
  });

  test(
    'Assistant updates survive restart and preserve the next user draft',
    () async {
      final conversation = await repository.createConversation();
      await repository.saveDraft(conversation.id, 'Następne pytanie');
      final assistant = await repository.addMessage(
        conversationId: conversation.id,
        authorId: 'bielik',
        text: 'Pierwszy',
      );
      await repository.updateMessage(assistant.id, 'Pierwszy i drugi fragment');
      await reopen();
      final restored = (await repository.getMessages(conversation.id)).single;
      expect(restored.id, assistant.id);
      expect(restored.authorId, 'bielik');
      expect(restored.text, 'Pierwszy i drugi fragment');
      expect(
        (await repository.getConversations()).single.draft,
        'Następne pytanie',
      );
    },
  );

  testWidgets(
    'Restores workspace history and drafts after a database restart',
    (tester) async {
      await tester.runAsync(() async {
        final workspace = ChatWorkspace(repository);
        await workspace.initialize();
        final firstId = workspace.selected.id;
        workspace.selected.draft.text = 'Trwała wiadomość';
        await workspace.sendMessage('Trwała wiadomość');
        final firstSize = workspace.selected.contentSizeBytes;
        await workspace.newChat();
        final secondId = workspace.selected.id;
        workspace.selected.draft.text = 'Szkic drugiej rozmowy';
        final secondSize = workspace.selected.contentSizeBytes;
        workspace.dispose();
        await workspace.flush();
        await reopen();

        final restored = ChatWorkspace(repository);
        await restored.initialize();
        expect(restored.error, isNull);
        expect(restored.conversations.map((chat) => chat.id), [
          secondId,
          firstId,
        ]);
        expect(restored.selected.draft.text, 'Szkic drugiej rozmowy');
        expect(restored.selected.contentSizeBytes, secondSize);
        restored.selectConversation(restored.conversations.last);
        expect(
          restored.selected.controller.messages.whereType<TextMessage>().map(
            (item) => item.text,
          ),
          ['Trwała wiadomość'],
        );
        expect(restored.selected.title, 'Trwała wiadomość');
        expect(restored.selected.contentSizeBytes, firstSize);
        restored.selected.draft.text = 'Po restarcie';
        await restored.sendMessage('Po restarcie');
        expect(restored.selected.draft.text, '');
        expect(
          (await repository.getMessages(firstId)).map((item) => item.text),
          ['Trwała wiadomość', 'Po restarcie'],
        );
        await restored.deleteConversation(restored.selected);
        expect(restored.selected.id, secondId);
        await restored.deleteConversation(restored.selected);
        expect(restored.conversations, hasLength(1));
        expect(restored.selected.id, isNot(anyOf(firstId, secondId)));
        restored.dispose();
        await restored.flush();
        await reopen();
        expect(await repository.getMessages(firstId), isEmpty);
        expect((await repository.getConversations()).single.draft, '');
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
