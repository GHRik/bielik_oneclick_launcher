import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class _Downloads implements ModelDownloadDataSource {
  final tasks = <DownloadTask>[];
  final enqueued = Completer<void>();
  int enqueueCount = 0;
  int cancelCount = 0;

  void setStatus(String id, DownloadTaskStatus status) {
    final i = tasks.indexWhere((task) => task.taskId == id);
    final old = tasks[i];
    tasks[i] = DownloadTask(
      taskId: id,
      status: status,
      progress: status == DownloadTaskStatus.complete ? 100 : 0,
      url: old.url,
      filename: old.filename,
      savedDir: old.savedDir,
      timeCreated: old.timeCreated,
      allowCellular: true,
    );
  }

  @override
  Future<List<DownloadTask>> loadTasks() async => tasks.toList();

  @override
  Future<String> enqueue({
    required String url,
    required String directory,
    required String filename,
  }) async {
    final id = 'task-${++enqueueCount}';
    tasks.add(DownloadTask(
      taskId: id,
      status: DownloadTaskStatus.enqueued,
      progress: 0,
      url: url,
      filename: filename,
      savedDir: directory,
      timeCreated: enqueueCount,
      allowCellular: true,
    ));
    if (!enqueued.isCompleted) enqueued.complete();
    return id;
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelCount++;
    setStatus(taskId, DownloadTaskStatus.canceled);
  }

  @override
  Future<void> remove(String taskId) async {
    tasks.removeWhere((task) => task.taskId == taskId);
  }
}

void main() {
  late Directory directory;
  late _Downloads downloads;
  late LocalModelFilesRepository repository;
  late List<int> bytes;
  late ModelFile model;

  LocalModelFilesRepository createRepository() => LocalModelFilesRepository(
    ModelFileDataSource(directory: () async => directory),
    downloads: downloads,
    pollInterval: const Duration(milliseconds: 1),
  );

  Future<void> finish({List<int>? content}) async {
    final task = downloads.tasks.last;
    await File('${task.savedDir}/${task.filename}').writeAsBytes(content ?? bytes);
    downloads.setStatus(task.taskId, DownloadTaskStatus.complete);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bielik-model-test-');
    downloads = _Downloads();
    repository = createRepository();
    bytes = List.generate(1024 * 128, (i) => i % 256);
    model = ModelFile(
      name: 'test.gguf',
      url: 'https://example.com/test.gguf',
      sizeBytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
    );
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('Delegates transfer, verifies hash and deletes the model after reopening', () async {
    final reports = <ModelDownloadProgress>[];
    final result = repository.download(model, reports.add);
    await downloads.enqueued.future;
    expect(downloads.tasks.single.url, model.url);
    expect(downloads.tasks.single.filename, 'test.gguf.part');
    await finish();
    await result;
    expect(reports.last.verifying, isTrue);
    expect(await repository.isDownloaded(model), isTrue);
    expect(downloads.tasks, isEmpty);
    final reopened = createRepository();
    expect(await reopened.isDownloaded(model), isTrue);
    await reopened.delete(model);
    expect(await reopened.isDownloaded(model), isFalse);
  });

  test('Restores a running background task without enqueuing a second one', () async {
    final file = await ModelFileDataSource(directory: () async => directory).file(model);
    await downloads.enqueue(url: model.url, directory: file.parent.path, filename: 'test.gguf.part');
    expect(await repository.hasPendingDownload(model), isTrue);
    final reopened = createRepository();
    final result = reopened.download(model, (_) {});
    await finish();
    await result;
    expect(downloads.enqueueCount, 1);
    expect(await reopened.isDownloaded(model), isTrue);
  });

  test('Verifies a task completed while the app was closed', () async {
    final file = await ModelFileDataSource(directory: () async => directory).file(model);
    await downloads.enqueue(url: model.url, directory: file.parent.path, filename: 'test.gguf.part');
    await finish();
    expect(await repository.isDownloaded(model), isFalse);
    expect(await repository.hasPendingDownload(model), isTrue);
    await repository.download(model, (_) {});
    expect(await repository.isDownloaded(model), isTrue);
    expect(downloads.enqueueCount, 1);
  });

  test('Rejects incorrect SHA and cleans the task and partial file', () async {
    final result = repository.download(model, (_) {});
    final assertion = expectLater(result, throwsFormatException);
    await downloads.enqueued.future;
    await finish(content: List.filled(bytes.length, 0));
    await assertion;
    expect(await repository.isDownloaded(model), isFalse);
    expect(downloads.tasks, isEmpty);
    expect(await File('${directory.path}/models/test.gguf.part').exists(), isFalse);
  });

  test('Cancels the native task and clears partial data', () async {
    final result = repository.download(model, (_) {});
    final assertion = expectLater(result, throwsA(isA<ModelDownloadCancelled>()));
    await downloads.enqueued.future;
    repository.cancelDownload();
    await assertion;
    expect(downloads.cancelCount, 1);
    expect(downloads.tasks, isEmpty);
    expect(await repository.isDownloaded(model), isFalse);
  });

  test('Native failure allows a new download', () async {
    final result = repository.download(model, (_) {});
    final assertion = expectLater(result, throwsStateError);
    await downloads.enqueued.future;
    downloads.setStatus(downloads.tasks.single.taskId, DownloadTaskStatus.failed);
    await assertion;
    expect(downloads.tasks, isEmpty);
    final retry = repository.download(model, (_) {});
    while (downloads.enqueueCount < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await finish();
    await retry;
    expect(await repository.isDownloaded(model), isTrue);
  });

  test('Rejects wrong size even when the native task reports completion', () async {
    final result = repository.download(model, (_) {});
    final assertion = expectLater(result, throwsFormatException);
    await downloads.enqueued.future;
    await finish(content: [1, 2, 3]);
    await assertion;
    expect(await repository.isDownloaded(model), isFalse);
  });
}
