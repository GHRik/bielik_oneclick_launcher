import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class LlmSettingsDataSource {
  const LlmSettingsDataSource(this.database);
  final AppDatabase database;

  Future<String?> load() async {
    final connection = await database.open();
    final rows = await connection.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['llm'],
    );
    return rows.isEmpty ? null : rows.single['value'] as String;
  }

  Future<void> save(String value) async {
    final connection = await database.open();
    await connection.rawInsert(
      'INSERT INTO settings (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      ['llm', value],
    );
  }
}
