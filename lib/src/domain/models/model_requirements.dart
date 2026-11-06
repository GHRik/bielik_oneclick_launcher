import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

class ModelRequirements {
  ModelRequirements.evaluate(
    BielikModel model, {
    double? availableStorageGb,
    double? availableRamGb,
  }) : storage = ResourceRequirement(
         requiredGb: model.downloadSizeMb / 1000,
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
