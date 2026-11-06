import 'package:flutter/foundation.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';

class ModelDownloadController extends ChangeNotifier {
  ModelDownloadController(this._repository);

  final ModelFilesRepository _repository;
  bool busy = false;
  bool checking = true;
  bool complete = false;
  bool visible = false;
  String? error;
  ModelDownloadProgress? _progress;
  bool _disposed = false;

  bool get isRunning => busy;
  bool get verifying => _progress?.verifying ?? false;
  double get progress => _progress?.fraction ?? 0;
  int get percent => (progress * 100).floor();
  String get speed => ((_progress?.bytesPerSecond ?? 0) / 1000000)
      .toStringAsFixed(1)
      .replaceAll('.', ',');
  String get remainingTime {
    final value = _progress;
    if (value == null || value.bytesPerSecond <= 0) return 'Obliczanie…';
    final seconds =
        ((value.totalBytes - value.receivedBytes) / value.bytesPerSecond)
            .ceil();
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }

  Future<void> select(BielikModel model) async {
    if (busy || _disposed) return;
    var pending = false;
    checking = true;
    complete = false;
    visible = false;
    error = null;
    _progress = null;
    _notify();
    try {
      complete =
          model.file != null && await _repository.isDownloaded(model.file!);
      if (!complete && model.file != null) {
        pending = await _repository.hasPendingDownload(model.file!);
      }
    } catch (_) {
      error = 'Nie udało się sprawdzić pobranych modeli.';
    } finally {
      checking = false;
      _notify();
    }
    if (pending && !_disposed) await start(model);
  }

  Future<void> start(BielikModel model) async {
    if (busy || checking || complete) return;
    final file = model.file;
    if (file == null) {
      error = 'Ten model nie ma adresu pobierania.';
      _notify();
      return;
    }
    busy = true;
    visible = true;
    error = null;
    _progress = null;
    _notify();
    try {
      await _repository.download(file, (value) {
        _progress = value;
        _notify();
      });
      complete = true;
    } on ModelDownloadCancelled {
      visible = false;
      _progress = null;
    } catch (_) {
      error = 'Nie udało się pobrać modelu. Sprawdź połączenie i wolne miejsce, a następnie spróbuj ponownie.';
      visible = false;
    } finally {
      busy = false;
      _notify();
    }
  }

  void cancel() => _repository.cancelDownload();

  Future<void> delete(BielikModel model) async {
    if (busy || checking || model.file == null) return;
    busy = true;
    error = null;
    _notify();
    try {
      await _repository.delete(model.file!);
      complete = false;
      visible = false;
      _progress = null;
    } catch (_) {
      error = 'Nie udało się usunąć pliku modelu. Spróbuj ponownie.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
