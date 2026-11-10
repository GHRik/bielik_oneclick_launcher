import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_system_prompt_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  test(
    'Default, custom and empty prompts survive database reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'prompt-settings',
      );
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/app.db',
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      final repository = SqliteSystemPromptRepository(database);
      expect(await repository.load(), '');
      for (final prompt in ['Odpowiadaj zwięźle po polsku.', '']) {
        await repository.save(prompt);
        await database.close();
        expect(await repository.load(), prompt);
      }
    },
  );
}
