import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

abstract interface class ModelFilesRepository {
  Future<bool> isDownloaded(ModelFile model);
  Future<bool> hasPendingDownload(ModelFile model);
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  );
  void cancelDownload();
  Future<void> delete(ModelFile model);
}
