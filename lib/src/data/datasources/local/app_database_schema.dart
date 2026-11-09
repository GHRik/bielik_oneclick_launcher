import 'package:sqflite/sqflite.dart';

class AppDatabaseSchema {
  static const version = 5;

  static Future<void> upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createSettings(database);
    if (oldVersion < 5) {
      final conversationColumns = await database.rawQuery(
        'PRAGMA table_info(conversations)',
      );
      if (!conversationColumns.any(
        (column) => column['name'] == 'last_used_at',
      )) {
        await database.execute(
          'ALTER TABLE conversations ADD COLUMN last_used_at INTEGER NOT NULL DEFAULT 0',
        );
        await database.execute(
          'UPDATE conversations SET last_used_at = created_at',
        );
      }
      if (!conversationColumns.any(
        (column) => column['name'] == 'draft_attachment',
      )) {
        await database.execute(
          'ALTER TABLE conversations ADD COLUMN draft_attachment TEXT',
        );
      }
      final messageColumns = await database.rawQuery(
        'PRAGMA table_info(messages)',
      );
      if (!messageColumns.any((column) => column['name'] == 'attachment')) {
        await database.execute(
          'ALTER TABLE messages ADD COLUMN attachment TEXT',
        );
      }
    }
  }

  static Future<void> _createSettings(Database database) => database.execute(
    'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL)',
  );

  static Future<void> create(Database database, int version) async {
    await _createSettings(database);
    await database.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        draft TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_used_at INTEGER NOT NULL DEFAULT 0,
        draft_attachment TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY NOT NULL,
        conversation_id INTEGER NOT NULL,
        author_id TEXT NOT NULL,
        text TEXT NOT NULL,
        attachment TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE INDEX messages_conversation_created_at_idx
      ON messages (conversation_id, created_at)
    ''');
  }
}
