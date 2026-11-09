import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  const attachment = TextAttachment(
    name: 'notatki.txt',
    text: 'Zażółć 🙂\nDrugi wiersz',
    sizeBytes: 31,
  );
  late Directory directory;
  late AppDatabase database;
  late SqliteChatRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('txt-attachments-');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, 'test.db'),
    );
    repository = SqliteChatRepository(SqliteChatDataSource(database));
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('Preserves a pending attachment after reopening the database', () async {
    final conversation = await repository.createConversation();
    await repository.saveDraftAttachment(conversation.id, attachment);
    await database.close();
    final restored =
        (await repository.getConversations()).single.draftAttachment!;
    expect(restored.name, attachment.name);
    expect(restored.text, attachment.text);
  });

  test(
    'Preserves sent attachment text independently of the original file',
    () async {
      final conversation = await repository.createConversation();
      await repository.addMessage(
        conversationId: conversation.id,
        authorId: 'local-user',
        text: 'Przeanalizuj',
        attachment: attachment,
      );
      await database.close();
      final restored = (await repository.getMessages(conversation.id)).single;
      expect(restored.attachment!.text, attachment.text);
      expect(restored.promptText, contains(attachment.text));
    },
  );

  test(
    'Submitting an attachment clears the pending attachment atomically',
    () async {
      final conversation = await repository.createConversation();
      await repository.saveDraftAttachment(conversation.id, attachment);
      await repository.addMessage(
        conversationId: conversation.id,
        authorId: 'local-user',
        text: '',
        attachment: attachment,
        clearDraft: true,
      );
      expect(
        (await repository.getConversations()).single.draftAttachment,
        isNull,
      );
      expect(
        (await repository.getMessages(conversation.id)).single.attachment,
        isNotNull,
      );
    },
  );

  for (final version in [2, 3]) {
    test('Upgrades schema $version without deleting existing messages', () async {
      final legacyPath = path.join(directory.path, 'legacy.db');
      final old = await databaseFactoryFfi.openDatabase(
        legacyPath,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, _) async {
            await db.execute(
              "CREATE TABLE conversations (id INTEGER PRIMARY KEY, title TEXT, draft TEXT, created_at INTEGER, updated_at INTEGER${version == 3 ? ', last_used_at INTEGER' : ''})",
            );
            await db.execute(
              'CREATE TABLE messages (id TEXT PRIMARY KEY, conversation_id INTEGER, author_id TEXT, text TEXT, created_at INTEGER)',
            );
            await db.execute(
              'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
            );
            await db.insert('conversations', {
              'id': 1,
              'title': 'Keep',
              'draft': '',
              'created_at': 1,
              'updated_at': 1,
            });
            await db.insert('messages', {
              'id': 'old',
              'conversation_id': 1,
              'author_id': 'local-user',
              'text': 'Preserved',
              'created_at': 1,
            });
          },
        ),
      );
      await old.close();
      final migrated = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: legacyPath,
      );
      try {
        final db = await migrated.open();
        expect((await db.query('messages')).single['text'], 'Preserved');
        await db.update('conversations', {
          'draft_attachment': 'test',
        }, where: 'id = 1');
        expect(await db.getVersion(), 4);
      } finally {
        await migrated.close();
      }
    });
  }
}
