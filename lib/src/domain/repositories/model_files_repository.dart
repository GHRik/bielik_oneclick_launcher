import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

abstract interface class ModelFilesRepository {
  Future<bool> isDownloaded(ModelFile model);
  Future<bool> hasPendingDownload(ModelFile model);

  /// Bytes kept from an interrupted download of [model] that the next
  /// [download] continues from, or 0 when it would start from the beginning.
  Future<int> partialDownloadBytes(ModelFile model);
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  );
  void cancelDownload();
  Future<void> delete(ModelFile model);
}
