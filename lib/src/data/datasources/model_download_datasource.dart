import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@pragma('vm:entry-point')
void modelDownloadCallback(String id, int status, int progress) {}

abstract interface class ModelDownloadDataSource {
  Future<List<DownloadTask>> loadTasks();
  Future<String> enqueue({
    required String url,
    required String directory,
    required String filename,
  });
  Future<void> cancel(String taskId);

  /// Removes the task record and, unless [deleteFile] is false, its file.
  Future<void> remove(String taskId, {bool deleteFile = true});

  /// Tells the plugin whether to keep the partial file of [taskId] when the
  /// transfer fails or is stopped. Returns false when that could not be
  /// arranged.
  Future<bool> keepPartialFile(String taskId, {bool keep = true});
}

class FlutterModelDownloadDataSource implements ModelDownloadDataSource {
  FlutterModelDownloadDataSource({
    this.taskDatabaseFactory,
    this.taskDatabasePath,
    this.keepPartialTimeout = const Duration(seconds: 2),
  });

  /// Where the plugin keeps its tasks; the defaults are its Android database.
  final DatabaseFactory? taskDatabaseFactory;
  final Future<String> Function()? taskDatabasePath;

  /// How long [keepPartialFile] waits for the plugin to save a new task.
  final Duration keepPartialTimeout;

  static Future<void> initialize() async {
    await FlutterDownloader.initialize();
    await FlutterDownloader.registerCallback(modelDownloadCallback, step: 1);
  }

  @override
  Future<List<DownloadTask>> loadTasks() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) {
      throw StateError('Nie udało się odczytać zadań pobierania.');
    }
    return tasks;
  }

  @override
  Future<String> enqueue({
    required String url,
    required String directory,
    required String filename,
  }) async {
    final id = await FlutterDownloader.enqueue(
      url: url,
      savedDir: directory,
      fileName: filename,
      openFileFromNotification: false,
      timeout: 60000,
    );
    if (id == null) throw StateError('Nie udało się rozpocząć pobierania.');
    return id;
  }

  @override
  Future<void> cancel(String taskId) =>
      FlutterDownloader.cancel(taskId: taskId);

  @override
  Future<void> remove(String taskId, {bool deleteFile = true}) =>
      FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: deleteFile);

  /// flutter_downloader deletes the partial file of a task that fails or is
  /// stopped, unless the task is marked resumable, and it sets that mark only
  /// when a download is paused through its API. The mark is a column of the
  /// plugin's own task table, so it is set there directly. The plugin saves a
  /// new task just after it returns the task ID, hence the short wait.
  ///
  /// When the table cannot be reached the download still works; it only
  /// starts from the beginning after an interruption, as it did before.
  @override
  Future<bool> keepPartialFile(String taskId, {bool keep = true}) async {
    try {
      final path =
          await (taskDatabasePath?.call() ??
              getDatabasesPath().then(
                (directory) => join(directory, 'download_tasks.db'),
              ));
      final deadline = DateTime.now().add(keepPartialTimeout);
      while (true) {
        if (await File(path).exists()) {
          final database = await (taskDatabaseFactory ?? databaseFactory)
              .openDatabase(
                path,
                options: OpenDatabaseOptions(singleInstance: false),
              );
          try {
            final marked = await database.rawUpdate(
              'UPDATE task SET resumable = ? WHERE task_id = ?',
              [keep ? 1 : 0, taskId],
            );
            if (marked > 0) return true;
          } finally {
            await database.close();
          }
        }
        if (!DateTime.now().isBefore(deadline)) return false;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } catch (_) {
      return false;
    }
  }
}
