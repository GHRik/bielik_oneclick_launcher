import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

class ModelRequirements {
  /// [downloadedGb] is the part of the model already written to storage. It
  /// no longer has to fit in the free space measured during a download.
  ModelRequirements.evaluate(
    BielikModel model, {
    double? availableStorageGb,
    double? availableRamGb,
    double downloadedGb = 0,
  }) : storage = ResourceRequirement(
         requiredGb: (model.downloadSizeMb / 1000 - downloadedGb).clamp(
           0,
           double.infinity,
         ),
         availableGb: availableStorageGb,
       ),
       ram = ResourceRequirement(
         requiredGb: model.requiredFreeRamGb,
         availableGb: availableRamGb,
       );

  final ResourceRequirement storage;
  final ResourceRequirement ram;

  bool get requiresConfirmation =>
      storage.status != RequirementStatus.sufficient ||
      ram.status != RequirementStatus.sufficient;
}
