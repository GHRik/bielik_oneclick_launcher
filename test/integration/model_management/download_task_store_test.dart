import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String databasePath;

  FlutterModelDownloadDataSource source({
    Duration timeout = const Duration(milliseconds: 300),
  }) => FlutterModelDownloadDataSource(
    taskDatabaseFactory: databaseFactoryFfi,
    taskDatabasePath: () async => databasePath,
    keepPartialTimeout: timeout,
  );

  /// The columns the download plugin's task table has that matter here.
  Future<void> createPluginDatabase({List<String> tasks = const []}) async {
    final database = await databaseFactoryFfi.openDatabase(databasePath);
    await database.execute(
      'CREATE TABLE task (task_id TEXT, status INTEGER, resumable TINYINT)',
    );
    for (final id in tasks) {
      await database.insert('task', {
        'task_id': id,
        'status': 2,
        'resumable': 0,
      });
    }
    await database.close();
  }

  Future<Map<String, Object?>> resumable() async {
    final database = await databaseFactoryFfi.openDatabase(databasePath);
    final rows = await database.query('task');
    await database.close();
    return {
      for (final row in rows) row['task_id']! as String: row['resumable'],
    };
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bielik-tasks-test-');
    databasePath = path.join(directory.path, 'download_tasks.db');
  });
  tearDown(() => directory.delete(recursive: true));

  group('Keeping the partial file of a download task', () {
    test('Marks only the given task as resumable', () async {
      await createPluginDatabase(tasks: ['first', 'second']);

      expect(await source().keepPartialFile('second'), isTrue);
      expect(await resumable(), {'first': 0, 'second': 1});
    });

    test('Clears the mark again on request', () async {
      await createPluginDatabase(tasks: ['first', 'second']);
      await source().keepPartialFile('first');
      await source().keepPartialFile('second');

      expect(await source().keepPartialFile('second', keep: false), isTrue);
      expect(await resumable(), {'first': 1, 'second': 0});
    });

    test('Waits for a task that the plugin saves a moment later', () async {
      await createPluginDatabase();
      final marked = source(timeout: const Duration(seconds: 5))
          .keepPartialFile('late');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      await database.insert('task', {
        'task_id': 'late',
        'status': 1,
        'resumable': 0,
      });
      await database.close();

      expect(await marked, isTrue);
      expect(await resumable(), {'late': 1});
    });

    test('Gives up when the task never appears', () async {
      await createPluginDatabase(tasks: ['other']);

      expect(await source().keepPartialFile('missing'), isFalse);
      expect(await resumable(), {'other': 0});
    });

    test('Does not create the database when the plugin has none', () async {
      expect(await source().keepPartialFile('task'), isFalse);
      expect(await File(databasePath).exists(), isFalse);
    });

    test('Reports failure for a database without the task table', () async {
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      await database.execute('CREATE TABLE other (id INTEGER)');
      await database.close();

      expect(await source().keepPartialFile('task'), isFalse);
    });
  });
}
