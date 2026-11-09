import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('Upgrading version 2 preserves conversations and settings', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bielik-migration-',
    );
    final file = path.join(directory.path, 'migration.db');
    final old = await databaseFactoryFfi.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE conversations (id INTEGER PRIMARY KEY, '
            'title TEXT, draft TEXT, created_at INTEGER, updated_at INTEGER)',
          );
          await db.execute(
            'CREATE TABLE messages (id TEXT PRIMARY KEY, conversation_id INTEGER, author_id TEXT, text TEXT, created_at INTEGER)',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
          );
          await db.insert('conversations', {
            'id': 1,
            'title': 'Existing',
            'draft': 'Keep me',
            'created_at': 100,
            'updated_at': 200,
          });
          await db.insert('settings', {'key': 'example', 'value': 'preserved'});
        },
      ),
    );
    await old.close();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: file,
    );
    try {
      final db = await database.open();
      final row = (await db.query('conversations')).single;
      expect(row, {
        'id': 1,
        'title': 'Existing',
        'draft': 'Keep me',
        'created_at': 100,
        'updated_at': 200,
        'last_used_at': 100,
        'draft_attachment': null,
      });
      expect((await db.query('settings')).single['value'], 'preserved');
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
