import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_app_theme_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late AppDatabase database;
  late SqliteAppThemeRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('theme-test');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(directory.path, 'app.db'),
    );
    repository = SqliteAppThemeRepository(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('A new installation uses the system theme', () async {
    expect(await repository.load(), AppThemePreference.system);
  });

  test('The preference survives closing and reopening the database', () async {
    await repository.save(AppThemePreference.dark);
    await database.close();
    expect(await repository.load(), AppThemePreference.dark);
  });

  test('Saving system mode replaces a previous override', () async {
    await repository.save(AppThemePreference.dark);
    await repository.save(AppThemePreference.system);
    expect(await repository.load(), AppThemePreference.system);
  });

  test('An unknown stored preference falls back to system mode', () async {
    final connection = await database.open();
    await connection.insert('settings', {
      'key': 'appearance.theme',
      'value': 'invalid',
    });
    expect(await repository.load(), AppThemePreference.system);
  });
}
