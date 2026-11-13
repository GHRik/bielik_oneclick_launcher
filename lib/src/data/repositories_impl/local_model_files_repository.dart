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
  Future<int> partialDownloadBytes(ModelFile model) async {
    final destination = await _files.file(model);
    if ((await _tasks(model, destination)).any(_recoverable)) return 0;
    final partial = File('${destination.path}.part');
    if (!await partial.exists()) return 0;
    final length = await partial.length();
    return length <= model.sizeBytes ? length : 0;
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
    var removeTask = false;
    File? partial;
    try {
      final destination = await _files.file(model);
      partial = File('${destination.path}.part');
      final tasks = await _tasks(model, destination);
      final pending = tasks.where(_recoverable).firstOrNull;
      if (pending != null) {
        taskId = pending.taskId;
      } else {
        // Tasks that ended without a model. The part they saved stays: the
        // plugin continues a transfer whose file already exists.
        for (final task in tasks) {
          await _downloads.remove(task.taskId, deleteFile: false);
        }
        var saved = await partial.exists() ? await partial.length() : 0;
        if (saved > model.sizeBytes) {
          await partial.delete();
          saved = 0;
        }
        if (_cancelled) throw ModelDownloadCancelled();
        // A part of full size only waits for verification.
        if (saved < model.sizeBytes) {
          taskId = await _downloads.enqueue(
            url: model.url,
            directory: destination.parent.path,
            filename: '${model.name}.part',
          );
        }
      }
      final keepsPartial =
          taskId != null && await _downloads.keepPartialFile(taskId);

      final watch = Stopwatch()..start();
      var previousBytes = await partial.exists() ? await partial.length() : 0;
      var previousTime = 0;
      while (taskId != null) {
        final task = (await _downloads.loadTasks())
            .where((task) => task.taskId == taskId)
            .firstOrNull;
        if (_cancelled) {
          // A cancelled task must not look paused to the plugin: it would
          // leave a "paused" notification for a file that is removed here.
          if (keepsPartial) {
            await _downloads.keepPartialFile(taskId, keep: false);
          }
          await _downloads.cancel(taskId);
          await _waitUntilStopped(taskId);
          removePartial = true;
          throw ModelDownloadCancelled();
        }
        if (task == null) throw StateError('Zadanie pobierania zniknęło.');
        if (task.status == DownloadTaskStatus.canceled ||
            task.status == DownloadTaskStatus.failed ||
            task.status == DownloadTaskStatus.undefined ||
            task.status == DownloadTaskStatus.paused) {
          // Nobody cancelled here, so the network dropped or Android stopped
          // the work. Keep the saved part when the plugin kept it too.
          removeTask = true;
          removePartial = !keepsPartial;
          throw ModelDownloadInterrupted();
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
      onProgress(
        ModelDownloadProgress(
          receivedBytes: model.sizeBytes,
          totalBytes: model.sizeBytes,
          bytesPerSecond: 0,
          verifying: true,
        ),
      );
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
        if (taskId != null && (removePartial || removeTask)) {
          await _downloads.remove(taskId, deleteFile: removePartial);
        }
        if (removePartial && partial != null && await partial.exists()) {
          await partial.delete();
        }
      } finally {
        _busy = false;
        _wake = null;
      }
    }
  }

  /// How long a cancelled task may stay enqueued before it counts as stopped.
  static const _unstartedTaskGrace = Duration(seconds: 2);

  /// Waits until the plugin reports that [taskId] is no longer active.
  ///
  /// A task that Android has not started yet, because it waits for a network
  /// or for free storage, is cancelled without its worker ever running, so
  /// nothing changes its status. Waiting for that would end in the timeout
  /// below and leave a task that reattaches on every start.
  Future<void> _waitUntilStopped(String taskId) async {
    final started = DateTime.now();
    final deadline = started.add(const Duration(seconds: 65));
    while (true) {
      final task = (await _downloads.loadTasks())
          .where((task) => task.taskId == taskId)
          .firstOrNull;
      if (task == null ||
          (task.status != DownloadTaskStatus.running &&
              task.status != DownloadTaskStatus.enqueued)) {
        return;
      }
      if (task.status == DownloadTaskStatus.enqueued &&
          DateTime.now().difference(started) >= _unstartedTaskGrace) {
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
