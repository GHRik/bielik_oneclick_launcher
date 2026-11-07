import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';

class LocalModelFilesRepository implements ModelFilesRepository {
  LocalModelFilesRepository(
    this._files, {
    ModelDownloadDataSource? downloads,
    this.pollInterval = const Duration(seconds: 1),
  }) : _downloads = downloads ?? FlutterModelDownloadDataSource();

  final ModelFileDataSource _files;
  final ModelDownloadDataSource _downloads;
  final Duration pollInterval;
  bool _busy = false;
  bool _cancelled = false;
  Completer<void>? _wake;

  @override
  Future<bool> isDownloaded(ModelFile model) async {
    final file = await _files.file(model);
    return await file.exists() && await file.length() == model.sizeBytes;
  }

  Future<List<DownloadTask>> _tasks(ModelFile model, File file) async {
    return (await _downloads.loadTasks())
        .where(
          (task) =>
              task.url == model.url &&
              task.savedDir == file.parent.path &&
              task.filename == '${model.name}.part',
        )
        .toList()
      ..sort((a, b) => b.timeCreated.compareTo(a.timeCreated));
  }

  bool _recoverable(DownloadTask task) =>
      task.status == DownloadTaskStatus.enqueued ||
      task.status == DownloadTaskStatus.running ||
      task.status == DownloadTaskStatus.complete;

  @override
  Future<bool> hasPendingDownload(ModelFile model) async {
    final tasks = await _tasks(model, await _files.file(model));
    return tasks.any(_recoverable);
  }

  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async {
    if (_busy) throw StateError('Trwa już pobieranie modelu.');
    _busy = true;
    _cancelled = false;
    String? taskId;
    var removePartial = false;
    File? partial;
    try {
      final destination = await _files.file(model);
      partial = File('${destination.path}.part');
      final tasks = await _tasks(model, destination);
      final pending = tasks.where(_recoverable).firstOrNull;
      if (pending != null) {
        taskId = pending.taskId;
      } else {
        for (final task in tasks) {
          await _downloads.remove(task.taskId);
        }
        if (await partial.exists()) await partial.delete();
        if (_cancelled) throw ModelDownloadCancelled();
        taskId = await _downloads.enqueue(
          url: model.url,
          directory: destination.parent.path,
          filename: '${model.name}.part',
        );
      }

      final watch = Stopwatch()..start();
      var previousBytes = await partial.exists() ? await partial.length() : 0;
      var previousTime = 0;
      while (true) {
        final task = (await _downloads.loadTasks())
            .where((task) => task.taskId == taskId)
            .firstOrNull;
        if (_cancelled) {
          await _downloads.cancel(taskId);
          await _waitUntilStopped(taskId);
          removePartial = true;
          throw ModelDownloadCancelled();
        }
        if (task == null) throw StateError('Zadanie pobierania zniknęło.');
        if (task.status == DownloadTaskStatus.canceled) {
          removePartial = true;
          throw ModelDownloadCancelled();
        }
        if (task.status == DownloadTaskStatus.failed ||
            task.status == DownloadTaskStatus.undefined ||
            task.status == DownloadTaskStatus.paused) {
          removePartial = true;
          throw StateError('Pobieranie zostało przerwane.');
        }
        final received = await partial.exists() ? await partial.length() : 0;
        final elapsed = watch.elapsedMilliseconds;
        final delta = elapsed - previousTime;
        final speed = delta > 0 && received >= previousBytes
            ? (received - previousBytes) * 1000 / delta
            : 0.0;
        previousBytes = received;
        previousTime = elapsed;
        onProgress(
          ModelDownloadProgress(
            receivedBytes: received.clamp(0, model.sizeBytes),
            totalBytes: model.sizeBytes,
            bytesPerSecond: speed,
            verifying: task.status == DownloadTaskStatus.complete,
          ),
        );
        if (task.status == DownloadTaskStatus.complete) break;
        _wake = Completer<void>();
        await Future.any([Future<void>.delayed(pollInterval), _wake!.future]);
        _wake = null;
      }

      removePartial = true;
      if (!await partial.exists() ||
          await partial.length() != model.sizeBytes) {
        throw const FormatException('Nieprawidłowy rozmiar pobranego pliku.');
      }
      final digest = await sha256
          .bind(
            partial.openRead().map((chunk) {
              if (_cancelled) throw ModelDownloadCancelled();
              return chunk;
            }),
          )
          .first;
      if (_cancelled) throw ModelDownloadCancelled();
      if (digest.toString() != model.sha256) {
        throw const FormatException('Pobrany plik jest uszkodzony.');
      }
      await partial.rename(destination.path);
    } finally {
      try {
        if (removePartial) {
          if (taskId != null) await _downloads.remove(taskId);
          if (partial != null && await partial.exists()) await partial.delete();
        }
      } finally {
        _busy = false;
        _wake = null;
      }
    }
  }

  Future<void> _waitUntilStopped(String taskId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 65));
    while (true) {
      final task = (await _downloads.loadTasks())
          .where((task) => task.taskId == taskId)
          .firstOrNull;
      if (task == null ||
          (task.status != DownloadTaskStatus.running &&
              task.status != DownloadTaskStatus.enqueued)) {
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Nie udało się jeszcze zatrzymać pobierania.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  void cancelDownload() {
    _cancelled = true;
    if (_wake != null && !_wake!.isCompleted) _wake!.complete();
  }

  @override
  Future<void> delete(ModelFile model) async {
    if (_busy) throw StateError('Najpierw zakończ pobieranie.');
    final file = await _files.file(model);
    for (final task in await _tasks(model, file)) {
      await _downloads.cancel(task.taskId);
      await _waitUntilStopped(task.taskId);
      await _downloads.remove(task.taskId);
    }
    if (await file.exists()) await file.delete();
    final partial = File('${file.path}.part');
    if (await partial.exists()) await partial.delete();
  }
}
