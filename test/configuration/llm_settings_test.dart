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

  group('LLM settings persistence', () {
    late Directory directory;
    late AppDatabase database;
    late SqliteLlmSettingsRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('settings-test');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: path.join(directory.path, 'app.db'),
      );
      repository = SqliteLlmSettingsRepository(LlmSettingsDataSource(database));
    });
    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    test('Returns no configuration before the first save', () async {
      expect(await repository.load(), isNull);
    });

    test('Preserves all configuration fields after reopening', () async {
      const configuration = LlmConfiguration(
        contextSize: 4096,
        responseTokens: 1000,
        safetyTokens: 48,
        numberOfThreads: 2,
        batchSize: 64,
        temperature: 0.5,
        topK: 20,
        topP: 0.8,
        minP: 0.1,
        repeatPenalty: 1.2,
        seed: 42,
      );
      await repository.save(configuration);
      await database.close();

      final restored = (await repository.load())!;

      expect(restored.contextSize, configuration.contextSize);
      expect(restored.responseTokens, configuration.responseTokens);
      expect(restored.safetyTokens, configuration.safetyTokens);
      expect(restored.numberOfThreads, configuration.numberOfThreads);
      expect(restored.batchSize, configuration.batchSize);
      expect(restored.temperature, configuration.temperature);
      expect(restored.topK, configuration.topK);
      expect(restored.topP, configuration.topP);
      expect(restored.minP, configuration.minP);
      expect(restored.repeatPenalty, configuration.repeatPenalty);
      expect(restored.seed, configuration.seed);
    });

    test(
      'Clears a previously saved seed when the seed field is empty',
      () async {
        final draft = LlmSettingsDraft(defaultLlmConfiguration);
        addTearDown(draft.dispose);
        draft.fields['seed']!.text = '42';
        await repository.save(draft.configuration());

        draft.fields['seed']!.text = '';
        await repository.save(draft.configuration());

        expect((await repository.load())!.seed, isNull);
      },
    );
  });

  group('Version 1 database migration', () {
    for (final hasSettings in [false, true]) {
      group(
        hasSettings
            ? 'With an existing settings table'
            : 'Without a settings table',
        () {
          late AppDatabase database;

          setUp(() async {
            final directory = await Directory.systemTemp.createTemp(
              'settings-migration-test',
            );
            addTearDown(() => directory.delete(recursive: true));
            final file = path.join(directory.path, 'app.db');
            final old = await databaseFactoryFfi.openDatabase(
              file,
              options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  await AppDatabaseSchema.create(db, version);
                  if (!hasSettings) await db.execute('DROP TABLE settings');
                },
              ),
            );
            if (hasSettings) {
              await old.insert('settings', {
                'key': 'llm',
                'value': '{"seed":42}',
              });
            }
            final id = await old.insert('conversations', {
              'title': 'Saved conversation',
              'draft': 'Saved draft',
              'created_at': 1,
              'updated_at': 2,
            });
            await old.insert('messages', {
              'id': 'saved-message',
              'conversation_id': id,
              'author_id': 'local-user',
              'text': 'Saved message',
              'created_at': 1,
            });
            await old.close();
            database = AppDatabase(
              factory: databaseFactoryFfi,
              databasePath: file,
            );
            addTearDown(database.close);
          });

          test('Upgrades the schema to version 2', () async {
            final connection = await database.open();

            expect(await connection.getVersion(), 2);
          });

          test('Preserves conversation data', () async {
            final connection = await database.open();
            final conversation = (await connection.query('conversations'))
                .single;

            expect(conversation['title'], 'Saved conversation');
            expect(conversation['draft'], 'Saved draft');
          });

          test('Preserves saved messages', () async {
            final connection = await database.open();

            expect(
              (await connection.query('messages')).single['text'],
              'Saved message',
            );
          });

          test('Preserves settings rows after reopening', () async {
            await database.open();
            await database.close();

            final connection = await database.open();
            final rows = await connection.query('settings');

            expect(
              rows,
              hasSettings
                  ? [
                      {'key': 'llm', 'value': '{"seed":42}'},
                    ]
                  : isEmpty,
            );
          });
        },
      );
    }
  });

  group('LLM settings input validation', () {
    for (final entry in <String, String>{
      'responseTokens': '2048',
      'temperature': 'NaN',
      'numberOfThreads': '1.5',
      'seed': '-1',
      'topP': '0',
    }.entries) {
      test('Rejects ${entry.key} = ${entry.value}', () {
        final draft = LlmSettingsDraft(defaultLlmConfiguration);
        addTearDown(draft.dispose);
        draft.fields[entry.key]!.text = entry.value;

        expect(draft.configuration, throwsFormatException);
      });
    }

    test('Accepts a decimal comma in temperature', () {
      final draft = LlmSettingsDraft(defaultLlmConfiguration);
      addTearDown(draft.dispose);
      draft.fields['temperature']!.text = '0,5';

      expect(draft.configuration().temperature, 0.5);
    });
  });

  group('Settings save action', () {
    for (final valid in [false, true]) {
      testWidgets(
        valid ? 'Saves valid settings' : 'Does not save invalid settings',
        (tester) async {
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
          draft.fields['contextSize']!.text = valid ? '4096' : 'invalid';
          draft.fields['numberOfThreads']!.text = '2';

          await tester.tap(find.text('Zapisz'));
          await tester.pumpAndSettle();

          if (valid) {
            expect(saved!.contextSize, 4096);
            expect(saved!.numberOfThreads, 2);
          } else {
            expect(saved, isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          draft.dispose();
        },
      );
    }
  });
}
