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
    tasks.add(
      DownloadTask(
        taskId: id,
        status: DownloadTaskStatus.enqueued,
        progress: 0,
        url: url,
        filename: filename,
        savedDir: directory,
        timeCreated: enqueueCount,
        allowCellular: true,
      ),
    );
    if (!enqueued.isCompleted) enqueued.complete();
    return id;
  }

  /// False imitates a task Android never started: cancelling it leaves the
  /// status unchanged, because no worker runs to update it.
  bool cancelUpdatesStatus = true;

  @override
  Future<void> cancel(String taskId) async {
    cancelCount++;
    if (cancelUpdatesStatus) setStatus(taskId, DownloadTaskStatus.canceled);
  }

  /// Mirrors the plugin: a removed task takes its file along on request.
  @override
  Future<void> remove(String taskId, {bool deleteFile = true}) async {
    for (final task in tasks.where((task) => task.taskId == taskId)) {
      final file = File('${task.savedDir}/${task.filename}');
      if (deleteFile && await file.exists()) await file.delete();
    }
    tasks.removeWhere((task) => task.taskId == taskId);
  }

  bool keepsPartialFiles = true;
  final kept = <String>[];

  @override
  Future<bool> keepPartialFile(String taskId, {bool keep = true}) async {
    if (keepsPartialFiles) keep ? kept.add(taskId) : kept.remove(taskId);
    return keepsPartialFiles;
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
    await File('${task.savedDir}/${task.filename}')
        .writeAsBytes(content ?? bytes);
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

  Future<void> completeDownload() async {
    final result = repository.download(model, (_) {});
    await downloads.enqueued.future;
    await finish();
    await result;
  }

  group('Model transfer and local storage', () {
    test('Enqueues the configured URL into a partial file', () async {
      final result = repository.download(model, (_) {});
      await downloads.enqueued.future;
      final task = downloads.tasks.single;
      await finish();
      await result;

      expect(task.url, model.url);
      expect(task.filename, 'test.gguf.part');
    });

    test('Reports verification before completing a download', () async {
      final reports = <ModelDownloadProgress>[];
      final result = repository.download(model, reports.add);
      await downloads.enqueued.future;

      await finish();
      await result;

      expect(reports.last.verifying, isTrue);
    });

    test('Makes a verified model available locally', () async {
      await completeDownload();

      expect(await repository.isDownloaded(model), isTrue);
      expect(downloads.tasks, isEmpty);
    });

    test(
      'Recognizes a downloaded model after reopening the repository',
      () async {
        await completeDownload();

        expect(await createRepository().isDownloaded(model), isTrue);
      },
    );

    test('Deletes a downloaded model through a reopened repository', () async {
      await completeDownload();
      final reopened = createRepository();

      await reopened.delete(model);

      expect(await reopened.isDownloaded(model), isFalse);
    });
  });

  group('Restoring native download tasks', () {
    Future<void> enqueueExisting() async {
      final file = await ModelFileDataSource(directory: () async => directory)
          .file(model);
      await downloads.enqueue(
        url: model.url,
        directory: file.parent.path,
        filename: 'test.gguf.part',
      );
    }

    test('Recognizes an existing pending task', () async {
      await enqueueExisting();

      expect(await repository.hasPendingDownload(model), isTrue);
    });

    test('Reattaches without enqueuing a duplicate transfer', () async {
      await enqueueExisting();
      final reopened = createRepository();

      final result = reopened.download(model, (_) {});
      await finish();
      await result;

      expect(downloads.enqueueCount, 1);
      expect(await reopened.isDownloaded(model), isTrue);
    });

    test('Keeps a completed native task pending until verification', () async {
      await enqueueExisting();
      await finish();

      expect(await repository.isDownloaded(model), isFalse);
      expect(await repository.hasPendingDownload(model), isTrue);
    });

    test('Verifies a download completed while the app was closed', () async {
      await enqueueExisting();
      await finish();

      await repository.download(model, (_) {});

      expect(await repository.isDownloaded(model), isTrue);
      expect(downloads.enqueueCount, 1);
    });
  });

  group('Download failure recovery', () {
    test('Rejects an incorrect SHA and removes partial data', () async {
      final result = repository.download(model, (_) {});
      final assertion = expectLater(result, throwsFormatException);
      await downloads.enqueued.future;

      await finish(content: List.filled(bytes.length, 0));
      await assertion;

      expect(await repository.isDownloaded(model), isFalse);
      expect(downloads.tasks, isEmpty);
      expect(
        await File('${directory.path}/models/test.gguf.part').exists(),
        isFalse,
      );
    });

    test('Cancels the native task and clears partial data', () async {
      final result = repository.download(model, (_) {});
      final assertion = expectLater(
        result,
        throwsA(isA<ModelDownloadCancelled>()),
      );
      await downloads.enqueued.future;

      repository.cancelDownload();
      await assertion;

      expect(downloads.cancelCount, 1);
      expect(downloads.tasks, isEmpty);
      expect(await repository.isDownloaded(model), isFalse);
    });

    Future<void> interrupt(
      DownloadTaskStatus status, {
      List<int>? saved,
    }) async {
      final result = repository.download(model, (_) {});
      final assertion = expectLater(
        result,
        throwsA(isA<ModelDownloadInterrupted>()),
      );
      await downloads.enqueued.future;
      final task = downloads.tasks.single;
      if (saved != null) {
        await File('${task.savedDir}/${task.filename}').writeAsBytes(saved);
      }
      downloads.setStatus(task.taskId, status);
      await assertion;
    }

    Future<void> waitForEnqueue(int count) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (downloads.enqueueCount < count &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(downloads.enqueueCount, count);
    }

    File partialFile() => File('${directory.path}/models/test.gguf.part');

    for (final status in [
      DownloadTaskStatus.failed,
      DownloadTaskStatus.canceled,
      DownloadTaskStatus.paused,
      DownloadTaskStatus.undefined,
    ]) {
      test('Reports a transfer that ended as $status as interrupted and '
          'removes its task', () async {
        await interrupt(status);

        expect(downloads.tasks, isEmpty);
      });
    }

    test('Asks the plugin to keep the partial file of a new task', () async {
      await completeDownload();

      expect(downloads.kept, ['task-1']);
    });

    test('Keeps the saved part of an interrupted transfer', () async {
      await interrupt(DownloadTaskStatus.failed, saved: bytes.sublist(0, 1000));

      expect(await partialFile().length(), 1000);
      expect(await repository.partialDownloadBytes(model), 1000);
    });

    test('Continues from the saved part in the next download', () async {
      await interrupt(DownloadTaskStatus.failed, saved: bytes.sublist(0, 1000));

      final retry = repository.download(model, (_) {});
      await waitForEnqueue(2);
      expect(await partialFile().length(), 1000);
      await finish();
      await retry;

      expect(await repository.isDownloaded(model), isTrue);
      expect(await repository.partialDownloadBytes(model), 0);
    });

    test('Removes the saved part when the plugin cannot keep it', () async {
      downloads.keepsPartialFiles = false;
      await interrupt(DownloadTaskStatus.failed, saved: bytes.sublist(0, 1000));

      expect(await partialFile().exists(), isFalse);
      expect(await repository.partialDownloadBytes(model), 0);
    });

    test('Reports no saved part while a transfer is pending', () async {
      final result = repository.download(model, (_) {});
      await downloads.enqueued.future;
      await partialFile().writeAsBytes(bytes.sublist(0, 1000));

      expect(await repository.partialDownloadBytes(model), 0);
      await finish();
      await result;
    });

    test('Discards a saved part larger than the model', () async {
      await Directory('${directory.path}/models').create(recursive: true);
      await partialFile().writeAsBytes([...bytes, 1]);

      expect(await repository.partialDownloadBytes(model), 0);
      final result = repository.download(model, (_) {});
      await downloads.enqueued.future;
      expect(await partialFile().exists(), isFalse);
      await finish();
      await result;

      expect(await repository.isDownloaded(model), isTrue);
    });

    test('Verifies a saved part of full size without a new transfer', () async {
      await Directory('${directory.path}/models').create(recursive: true);
      await partialFile().writeAsBytes(bytes);
      final reports = <ModelDownloadProgress>[];

      await repository.download(model, reports.add);

      expect(downloads.enqueueCount, 0);
      expect(reports.last.verifying, isTrue);
      expect(await repository.isDownloaded(model), isTrue);
    });

    test('Removes a saved part of full size that fails verification', () async {
      await Directory('${directory.path}/models').create(recursive: true);
      await partialFile().writeAsBytes(List.filled(bytes.length, 0));

      await expectLater(
        repository.download(model, (_) {}),
        throwsFormatException,
      );

      expect(await partialFile().exists(), isFalse);
    });

    test('Cancelling still removes the saved part', () async {
      final result = repository.download(model, (_) {});
      final assertion = expectLater(
        result,
        throwsA(isA<ModelDownloadCancelled>()),
      );
      await downloads.enqueued.future;
      await partialFile().writeAsBytes(bytes.sublist(0, 1000));

      repository.cancelDownload();
      await assertion;

      expect(await partialFile().exists(), isFalse);
      expect(await repository.partialDownloadBytes(model), 0);
      expect(downloads.kept, isEmpty);
    });

    test('Cancels a task that Android never started', () async {
      downloads.cancelUpdatesStatus = false;
      final result = repository.download(model, (_) {});
      final assertion = expectLater(
        result,
        throwsA(isA<ModelDownloadCancelled>()),
      );
      await downloads.enqueued.future;

      repository.cancelDownload();
      await assertion.timeout(const Duration(seconds: 10));

      expect(downloads.tasks, isEmpty);
      expect(await repository.hasPendingDownload(model), isFalse);
    });

    test('Deletes a model whose task Android never started', () async {
      downloads.cancelUpdatesStatus = false;
      await downloads.enqueue(
        url: model.url,
        directory: '${directory.path}/models',
        filename: 'test.gguf.part',
      );

      await repository.delete(model).timeout(const Duration(seconds: 10));

      expect(downloads.tasks, isEmpty);
    });

    test('Deleting the model removes a saved part', () async {
      await interrupt(DownloadTaskStatus.failed, saved: bytes.sublist(0, 1000));

      await repository.delete(model);

      expect(await partialFile().exists(), isFalse);
    });

    test('Rejects incorrect size despite native completion', () async {
      final result = repository.download(model, (_) {});
      final assertion = expectLater(result, throwsFormatException);
      await downloads.enqueued.future;

      await finish(content: [1, 2, 3]);
      await assertion;

      expect(await repository.isDownloaded(model), isFalse);
    });
  });
}
