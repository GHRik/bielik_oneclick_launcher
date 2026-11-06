import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';

class InMemoryModelFilesRepository implements ModelFilesRepository {
  final downloaded = <String>{};
  Completer<void>? _pending;
  void Function(ModelDownloadProgress)? _onProgress;

  @override
  Future<bool> isDownloaded(ModelFile model) async =>
      downloaded.contains(model.name);

  @override
  Future<bool> hasPendingDownload(ModelFile model) async => false;

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
