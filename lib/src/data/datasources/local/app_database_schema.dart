import 'package:sqflite/sqflite.dart';

class AppDatabaseSchema {
  static const version = 1;

  static Future<void> create(Database database, int version) async {
    await database.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        draft TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY NOT NULL,
        conversation_id INTEGER NOT NULL,
        author_id TEXT NOT NULL,
        text TEXT NOT NULL,
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
