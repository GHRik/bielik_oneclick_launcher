import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `FlutterModelDownloadDataSource.keepPartialFile` writes to the task table
/// of flutter_downloader. These checks read the plugin source that this
/// project resolves to, so a plugin upgrade that renames the table, the
/// columns or the rule that keeps a partial file fails here instead of
/// silently turning resumed downloads back into downloads from zero.
void main() {
  late Directory plugin;

  String source(String name) => File(
    '${plugin.path}/android/src/main/kotlin/vn/hunghd/flutterdownloader/$name',
  ).readAsStringSync();

  setUpAll(() {
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final package = (config['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((package) => package['name'] == 'flutter_downloader');
    plugin = Directory.fromUri(
      Directory('.dart_tool').absolute.uri
          .resolve(package['rootUri'] as String),
    );
  });

  group('flutter_downloader task table', () {
    test('Is stored in download_tasks.db', () {
      expect(
        source('TaskDbHelper.kt'),
        contains('DATABASE_NAME = "download_tasks.db"'),
      );
    });

    test('Has the table and columns that the resumable mark uses', () {
      final entry = source('TaskEntry.kt');

      expect(entry, contains('TABLE_NAME = "task"'));
      expect(entry, contains('COLUMN_NAME_TASK_ID = "task_id"'));
      expect(entry, contains('COLUMN_NAME_RESUMABLE = "resumable"'));
    });

    test('Keeps the partial file only of a resumable task', () {
      expect(
        source('DownloadWorker.kt'),
        contains('task.status != DownloadStatus.COMPLETE && !task.resumable'),
      );
    });

    test('Continues a transfer whose partial file exists', () {
      final worker = source('DownloadWorker.kt');

      expect(worker, contains('if (partialFile.exists()) {'));
      expect(worker, contains('"Range", "bytes=\$downloadedBytes-"'));
    });
  });
}
