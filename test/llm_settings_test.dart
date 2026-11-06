import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database_schema.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/llm_settings_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_llm_settings_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/llm_settings_page.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Migrates v1 without losing chats and persists all LLM settings',
    () async {
      final directory = await Directory.systemTemp.createTemp('settings-test');
      final file = path.join(directory.path, 'app.db');
      final old = await databaseFactoryFfi.openDatabase(
        file,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await AppDatabaseSchema.create(db, version);
            await db.execute('DROP TABLE settings');
            await db.insert('conversations', {
              'title': 'Zachowaj',
              'created_at': 1,
              'updated_at': 1,
            });
          },
        ),
      );
      await old.close();
      final db = AppDatabase(factory: databaseFactoryFfi, databasePath: file);
      final repository = SqliteLlmSettingsRepository(LlmSettingsDataSource(db));
      expect(await repository.load(), isNull);
      final draft = LlmSettingsDraft(defaultLlmConfiguration);
      draft.fields['numberOfThreads']!.text = '2';
      draft.fields['temperature']!.text = '0,5';
      draft.fields['seed']!.text = '42';
      final configuration = draft.configuration();
      await repository.save(configuration);
      await db.close();
      final restored = await repository.load();
      expect(restored!.numberOfThreads, 2);
      expect(restored.temperature, 0.5);
      expect(restored.seed, 42);
      expect(restored.contextSize, configuration.contextSize);
      expect(restored.responseTokens, configuration.responseTokens);
      expect(restored.safetyTokens, configuration.safetyTokens);
      expect(restored.batchSize, configuration.batchSize);
      expect(restored.topK, configuration.topK);
      expect(restored.topP, configuration.topP);
      expect(restored.minP, configuration.minP);
      expect(restored.repeatPenalty, configuration.repeatPenalty);
      expect(
        (await (await db.open()).query('conversations')).single['title'],
        'Zachowaj',
      );
      draft.fields['seed']!.text = '';
      await repository.save(draft.configuration());
      expect((await repository.load())!.seed, isNull);
      draft.dispose();
      await db.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'Rejects invalid budgets, non-finite values and fractional thread counts',
    () {
      final draft = LlmSettingsDraft(defaultLlmConfiguration);
      for (final entry in {
        'responseTokens': '2048',
        'temperature': 'NaN',
        'numberOfThreads': '1.5',
        'seed': '-1',
        'topP': '0',
      }.entries) {
        draft.reset();
        draft.fields[entry.key]!.text = entry.value;
        expect(draft.configuration, throwsFormatException);
      }
      draft.dispose();
    },
  );

  testWidgets('Save validates before invoking persistence', (tester) async {
    final draft = LlmSettingsDraft(defaultLlmConfiguration);
    LlmConfiguration? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: LlmSettingsPage(
          draft: draft,
          onSave: (configuration) async {
            saved = configuration;
          },
        ),
      ),
    );
    draft.fields['contextSize']!.text = 'invalid';
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    draft.fields['contextSize']!.text = '4096';
    draft.fields['numberOfThreads']!.text = '2';
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(saved!.contextSize, 4096);
    expect(saved!.numberOfThreads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    draft.dispose();
  });
}
