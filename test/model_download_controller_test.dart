import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_model_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';

import 'support/in_memory_model_files_repository.dart';

class _BackgroundRepository extends InMemoryModelFilesRepository {
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
  test('Reattaches to a persisted task and disposal does not cancel transfer', () async {
    final repository = _BackgroundRepository();
    final controller = ModelDownloadController(repository);
    final selection = controller.select(bielikModels.first);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isRunning, isTrue);
    expect(controller.visible, isTrue);
    controller.dispose();
    expect(repository.cancellations, 0);
    repository.finish();
    await selection;
    expect(await repository.isDownloaded(bielikModels.first.file!), isTrue);
  });
}
