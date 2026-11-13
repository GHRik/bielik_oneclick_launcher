import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';

class _BackgroundRepository extends _ModelFilesRepository {
  int cancellations = 0;

  @override
  Future<bool> hasPendingDownload(ModelFile model) async => true;

  @override
  void cancelDownload() {
    cancellations++;
    super.cancelDownload();
  }
}

void main() {
  group('Interrupted download', () {
    Future<ModelDownloadController> interrupt(int savedBytes) async {
      final repository = _InterruptedRepository()..savedBytes = savedBytes;
      final controller = ModelDownloadController(repository);
      addTearDown(controller.dispose);
      await controller.select(bielikModels.first);
      await controller.start(bielikModels.first);
      return controller;
    }

    test('Tells that the saved part will be continued', () async {
      final controller = await interrupt(400000000);

      expect(controller.savedBytes, 400000000);
      expect(controller.error, contains('Pobrana część jest zachowana'));
      expect(controller.visible, isFalse);
      expect(controller.busy, isFalse);
    });

    test('Asks to check the connection when nothing was saved', () async {
      final controller = await interrupt(0);

      expect(controller.savedBytes, 0);
      expect(controller.error, contains('spróbuj ponownie'));
    });

    test('Forgets a saved part that a failed download removed', () async {
      final repository = _FailingRepository()..savedBytes = 400000000;
      final controller = ModelDownloadController(repository);
      addTearDown(controller.dispose);
      await controller.select(bielikModels.first);
      expect(controller.savedBytes, 400000000);

      await controller.start(bielikModels.first);

      expect(controller.savedBytes, 0);
      expect(controller.error, contains('Nie udało się pobrać modelu'));
    });

    test('Finds a part saved before the app was opened', () async {
      final repository = _ModelFilesRepository()..savedBytes = 123;
      final controller = ModelDownloadController(repository);
      addTearDown(controller.dispose);

      await controller.select(bielikModels.first);

      expect(controller.savedBytes, 123);
      expect(controller.isRunning, isFalse);
    });

    test('Forgets the saved part after the model is deleted', () async {
      final repository = _ModelFilesRepository()..savedBytes = 123;
      final controller = ModelDownloadController(repository);
      addTearDown(controller.dispose);
      await controller.select(bielikModels.first);

      await controller.delete(bielikModels.first);

      expect(controller.savedBytes, 0);
    });

    test('Forgets the saved part once the download completes', () async {
      final repository = _ModelFilesRepository()..savedBytes = 123;
      final controller = ModelDownloadController(repository);
      addTearDown(controller.dispose);
      await controller.select(bielikModels.first);
      final download = controller.start(bielikModels.first);
      await Future<void>.delayed(Duration.zero);
      repository.finish();
      await download;

      expect(controller.complete, isTrue);
      expect(controller.savedBytes, 0);
    });
  });

  group('Background download lifecycle', () {
    late _BackgroundRepository repository;
    late ModelDownloadController controller;
    late Future<void> selection;
    var disposed = false;

    setUp(() async {
      disposed = false;
      repository = _BackgroundRepository();
      controller = ModelDownloadController(repository);
      selection = controller.select(bielikModels.first);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() async {
      if (!disposed) repository.finish();
      await selection;
      if (!disposed) controller.dispose();
    });

    test('Reattaches to a pending persisted download', () {
      expect(controller.isRunning, isTrue);
      expect(controller.visible, isTrue);
    });

    test('Disposing the controller does not cancel the transfer', () async {
      controller.dispose();
      disposed = true;
      repository.finish();
      await selection;

      expect(repository.cancellations, 0);
      expect(await repository.isDownloaded(bielikModels.first.file!), isTrue);
    });
  });
}

/// A resumed download that fails verification: the saved part is removed.
class _FailingRepository extends _ModelFilesRepository {
  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async {
    savedBytes = 0;
    throw const FormatException('Pobrany plik jest uszkodzony.');
  }
}

class _InterruptedRepository extends _ModelFilesRepository {
  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async => throw ModelDownloadInterrupted();
}

class _ModelFilesRepository implements ModelFilesRepository {
  final downloaded = <String>{};
  Completer<void>? _pending;
  void Function(ModelDownloadProgress)? _onProgress;

  @override
  Future<bool> isDownloaded(ModelFile model) async =>
      downloaded.contains(model.name);

  @override
  Future<bool> hasPendingDownload(ModelFile model) async => false;

  int savedBytes = 0;

  @override
  Future<int> partialDownloadBytes(ModelFile model) async => savedBytes;

  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async {
    _pending = Completer<void>();
    _onProgress = onProgress;
    await _pending!.future;
    downloaded.add(model.name);
  }

  void report(ModelDownloadProgress value) => _onProgress!(value);

  void finish() => _pending!.complete();

  @override
  void cancelDownload() {
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.completeError(ModelDownloadCancelled());
    }
  }

  @override
  Future<void> delete(ModelFile model) async => downloaded.remove(model.name);
}
