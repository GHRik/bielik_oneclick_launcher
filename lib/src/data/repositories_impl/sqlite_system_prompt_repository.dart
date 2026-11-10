import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class SqliteSystemPromptRepository {
  const SqliteSystemPromptRepository(this.database);
  final AppDatabase database;

  Future<String> load() async {
    final connection = await database.open();
    final rows = await connection.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['llm.additional_system_prompt'],
    );
    return rows.isEmpty ? '' : rows.single['value'] as String;
  }

  Future<void> save(String prompt) async {
    final connection = await database.open();
    await connection.rawInsert(
      'INSERT INTO settings (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      ['llm.additional_system_prompt', prompt],
    );
  }
}
