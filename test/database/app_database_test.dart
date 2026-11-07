import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show DatabaseException;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String databasePath;
  late AppDatabase database;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bielik-sqlite-test-');
    databasePath = path.join(directory.path, AppDatabase.fileName);
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<int> insertConversation({String draft = ''}) async {
    final connection = await database.open();
    return connection.insert('conversations', {
      'title': 'My conversation',
      'draft': draft,
      'created_at': 1000,
      'updated_at': 2000,
    });
  }

  Future<void> insertMessage(int conversationId) async {
    final connection = await database.open();
    await connection.insert('messages', {
      'id': 'message-1',
      'conversation_id': conversationId,
      'author_id': 'local-user',
      'text': 'Hello Bielik!',
      'created_at': 1500,
    });
  }

  group('Database initialization', () {
    test('Shares the connection between concurrent opens', () async {
      final connections = await Future.wait([database.open(), database.open()]);

      expect(connections.first, same(connections.last));
    });

    test('Creates the database file', () async {
      await database.open();

      expect(await File(databasePath).exists(), isTrue);
    });

    test('Initializes schema version 2', () async {
      final connection = await database.open();

      expect(
        (await connection.rawQuery('PRAGMA user_version'))
            .single['user_version'],
        2,
      );
    });

    test('Enables foreign key enforcement', () async {
      final connection = await database.open();

      expect(
        (await connection.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
    });

    for (final name in [
      'conversations',
      'messages',
      'messages_conversation_created_at_idx',
    ]) {
      test('Creates the $name schema object', () async {
        final connection = await database.open();
        final schema = await connection.rawQuery(
          "SELECT name FROM sqlite_master WHERE name = ?",
          [name],
        );

        expect(schema, hasLength(1));
      });
    }
  });

  group('Database persistence', () {
    test('Preserves conversation identity and title after reopening', () async {
      final id = await insertConversation();
      await database.close();

      final connection = await database.open();
      final conversation = (await connection.query('conversations')).single;

      expect(conversation['id'], id);
      expect(conversation['title'], 'My conversation');
    });

    test('Preserves a draft after reopening', () async {
      await insertConversation(draft: 'Unfinished message');
      await database.close();

      final connection = await database.open();

      expect(
        (await connection.query('conversations')).single['draft'],
        'Unfinished message',
      );
    });

    test('Preserves a message after reopening', () async {
      await insertMessage(await insertConversation());
      await database.close();

      final connection = await database.open();

      expect(
        (await connection.query('messages')).single['text'],
        'Hello Bielik!',
      );
    });
  });

  group('Conversation integrity', () {
    test('Rejects a message without an existing conversation', () async {
      await expectLater(insertMessage(999), throwsA(isA<DatabaseException>()));
    });

    test('Defaults a new conversation draft to empty text', () async {
      final connection = await database.open();
      await connection.insert('conversations', {
        'title': 'New',
        'created_at': 1000,
        'updated_at': 1000,
      });

      expect((await connection.query('conversations')).single['draft'], '');
    });

    test('Deletes messages when their conversation is deleted', () async {
      final id = await insertConversation();
      await insertMessage(id);
      final connection = await database.open();

      await connection.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [id],
      );

      expect(await connection.query('messages'), isEmpty);
    });
  });
}
