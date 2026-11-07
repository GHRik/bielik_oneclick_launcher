import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show DatabaseException;

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

  test(
    'Creates schema, enables foreign keys and shares concurrent opens',
    () async {
      final connections = await Future.wait([database.open(), database.open()]);
      final connection = connections.first;
      expect(identical(connection, connections.last), isTrue);
      expect(await File(databasePath).exists(), isTrue);
      expect(
        (await connection.rawQuery('PRAGMA user_version'))
            .single['user_version'],
        2,
      );
      expect(
        (await connection.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      final schema = await connection.rawQuery(
        "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
      );
      expect(
        schema.map((row) => row['name']),
        containsAll([
          'conversations',
          'messages',
          'messages_conversation_created_at_idx',
        ]),
      );
    },
  );

  test(
    'Keeps conversations, drafts and messages after closing and reopening',
    () async {
      final connection = await database.open();
      final id = await connection.insert('conversations', {
        'title': 'Moja rozmowa',
        'draft': 'Niedokończona wiadomość',
        'created_at': 1000,
        'updated_at': 2000,
      });
      await connection.insert('messages', {
        'id': 'message-1',
        'conversation_id': id,
        'author_id': 'local-user',
        'text': 'Cześć Bielik!',
        'created_at': 1500,
      });

      await database.close();
      database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      final reopened = await database.open();
      final conversation = (await reopened.query('conversations')).single;
      expect(conversation['id'], id);
      expect(conversation['title'], 'Moja rozmowa');
      expect(conversation['draft'], 'Niedokończona wiadomość');
      expect(
        (await reopened.query('messages')).single['text'],
        'Cześć Bielik!',
      );
      expect(
        (await reopened.rawQuery('PRAGMA user_version')).single['user_version'],
        2,
      );
    },
  );

  test('Rejects orphan messages and cascades conversation deletion', () async {
    final connection = await database.open();
    await expectLater(
      connection.insert('messages', {
        'id': 'orphan-message',
        'conversation_id': 999,
        'author_id': 'local-user',
        'text': 'Bez rozmowy',
        'created_at': 1000,
      }),
      throwsA(isA<DatabaseException>()),
    );
    final id = await connection.insert('conversations', {
      'title': 'Do usunięcia',
      'created_at': 1000,
      'updated_at': 1000,
    });
    expect((await connection.query('conversations')).single['draft'], '');
    await connection.insert('messages', {
      'id': 'message-1',
      'conversation_id': id,
      'author_id': 'local-user',
      'text': 'Wiadomość',
      'created_at': 1000,
    });
    await connection.delete('conversations', where: 'id = ?', whereArgs: [id]);
    expect(await connection.query('messages'), isEmpty);
  });
}
