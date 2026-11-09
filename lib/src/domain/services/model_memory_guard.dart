import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

class InsufficientModelMemory implements Exception {
  const InsufficientModelMemory(this.requiredGb, this.availableGb);

  final double requiredGb;
  final double availableGb;
}

class ModelMemoryGuard {
  const ModelMemoryGuard(this.resources, this.models);

  final DeviceResourcesRepository resources;
  final List<BielikModel> models;

  Future<void> check(ModelFile file) async {
    for (final model in models) {
      if (model.file?.sha256 != file.sha256) continue;
      final available = (await resources.read()).availableRamGb;
      if (available != null && available < model.requiredFreeRamGb) {
        throw InsufficientModelMemory(model.requiredFreeRamGb, available);
      }
      return;
    }
  }
}
