import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_theme_repository.dart';

class SqliteAppThemeRepository implements AppThemeRepository {
  const SqliteAppThemeRepository(this.database);

  final AppDatabase database;

  @override
  Future<AppThemePreference> load() async {
    final connection = await database.open();
    final rows = await connection.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['appearance.theme'],
    );
    if (rows.isEmpty) return AppThemePreference.system;
    final value = rows.single['value'];
    return AppThemePreference.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemePreference.system,
    );
  }

  @override
  Future<void> save(AppThemePreference preference) async {
    final connection = await database.open();
    await connection.rawInsert(
      'INSERT INTO settings (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      ['appearance.theme', preference.name],
    );
  }
}
