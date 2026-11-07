import 'package:flutter_downloader/flutter_downloader.dart';

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
  Future<void> remove(String taskId);
}

class FlutterModelDownloadDataSource implements ModelDownloadDataSource {
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
  Future<void> remove(String taskId) =>
      FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
}
