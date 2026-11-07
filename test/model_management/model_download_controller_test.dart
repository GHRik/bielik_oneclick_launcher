import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';

import '../support/in_memory_model_files_repository.dart';

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
