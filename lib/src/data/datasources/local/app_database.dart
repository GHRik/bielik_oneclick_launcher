import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database_schema.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.databasePath})
      : _factory = factory ?? databaseFactory;

  static const fileName = 'bielik.db';

  final DatabaseFactory _factory;
  final String? databasePath;
  Future<Database>? _opening;

  Future<Database> open() => _opening ??= _openDatabase();

  Future<Database> _openDatabase() async {
    try {
      final resolvedPath = databasePath ??
          path.join(await _factory.getDatabasesPath(), fileName);
      return await _factory.openDatabase(
        resolvedPath,
        options: OpenDatabaseOptions(
          version: AppDatabaseSchema.version,
          onConfigure: (database) =>
              database.execute('PRAGMA foreign_keys = ON'),
          onCreate: AppDatabaseSchema.create,
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    final database = await opening;
    await database.close();
    if (identical(_opening, opening)) _opening = null;
  }
}
