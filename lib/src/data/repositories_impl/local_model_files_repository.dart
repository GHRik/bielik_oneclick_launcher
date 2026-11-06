import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';

class LocalModelFilesRepository implements ModelFilesRepository {
  LocalModelFilesRepository(this._files);

  final ModelFileDataSource _files;
  HttpClient? _client;
  bool _cancelled = false;

  @override
  Future<bool> isDownloaded(ModelFile model) async {
    final file = await _files.file(model);
    return await file.exists() && await file.length() == model.sizeBytes;
  }

  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async {
    if (_client != null) throw StateError('Trwa już pobieranie modelu.');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..autoUncompress = false;
    _client = client;
    _cancelled = false;
    File? partial;
    try {
      final destination = await _files.file(model);
      partial = File('${destination.path}.part');
      _checkCancelled();
      final request = await client.getUrl(Uri.parse(model.url));
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Serwer zwrócił błąd HTTP ${response.statusCode}.');
      }
      if (response.contentLength >= 0 &&
          response.contentLength != model.sizeBytes) {
        throw const FormatException(
          'Rozmiar pliku na serwerze jest niezgodny.',
        );
      }
      final watch = Stopwatch()..start();
      var received = 0;
      var lastReport = 0;
      final sink = partial.openWrite();
      try {
        await sink.addStream(
          response.timeout(const Duration(seconds: 60)).map((chunk) {
            _checkCancelled();
            received += chunk.length;
            if (received > model.sizeBytes) {
              throw const FormatException('Pobrany plik jest za duży.');
            }
            final elapsed = watch.elapsedMilliseconds;
            if (elapsed - lastReport >= 250 || received == model.sizeBytes) {
              lastReport = elapsed;
              onProgress(
                ModelDownloadProgress(
                  receivedBytes: received,
                  totalBytes: model.sizeBytes,
                  bytesPerSecond: received / (elapsed > 0 ? elapsed / 1000 : 1),
                ),
              );
            }
            return chunk;
          }),
        );
        await sink.flush();
      } finally {
        await sink.close();
      }
      _checkCancelled();
      if (received != model.sizeBytes) {
        throw const FormatException('Pobieranie zakończyło się przedwcześnie.');
      }
      onProgress(
        ModelDownloadProgress(
          receivedBytes: received,
          totalBytes: model.sizeBytes,
          bytesPerSecond: 0,
          verifying: true,
        ),
      );
      final digest = await sha256
          .bind(
            partial.openRead().map((chunk) {
              _checkCancelled();
              return chunk;
            }),
          )
          .first;
      _checkCancelled();
      if (digest.toString() != model.sha256) {
        throw const FormatException(
          'Plik jest uszkodzony. Pobierz go ponownie.',
        );
      }
      await partial.rename(destination.path);
    } catch (_) {
      if (_cancelled) throw ModelDownloadCancelled();
      rethrow;
    } finally {
      client.close(force: true);
      if (partial != null && await partial.exists()) await partial.delete();
      _client = null;
    }
  }

  void _checkCancelled() {
    if (_cancelled) throw ModelDownloadCancelled();
  }

  @override
  void cancelDownload() {
    _cancelled = true;
    _client?.close(force: true);
  }

  @override
  Future<void> delete(ModelFile model) async {
    if (_client != null) throw StateError('Najpierw zakończ pobieranie.');
    final file = await _files.file(model);
    if (await file.exists()) await file.delete();
    final partial = File('${file.path}.part');
    if (await partial.exists()) await partial.delete();
  }
}
