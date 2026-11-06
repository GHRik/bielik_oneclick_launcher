import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_model_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_requirements.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

void main() {
  test('One policy decides confirmation and exposes resource statuses', () {
    final model = bielikModels.first;
    for (final available in <double?>[null, -1, double.nan, double.infinity, 0]) {
      final result = ModelRequirements.evaluate(model, availableStorageGb: available, availableRamGb: 4);
      expect(result.requiresConfirmation, isTrue);
    }
    final sufficient = ModelRequirements.evaluate(model, availableStorageGb: 1.7, availableRamGb: 4);
    expect(sufficient.requiresConfirmation, isFalse);
    expect(sufficient.storage.status, RequirementStatus.sufficient);
    expect(sufficient.ram.status, RequirementStatus.sufficient);
    final lowRam = ModelRequirements.evaluate(model, availableStorageGb: 5, availableRamGb: 3);
    expect(lowRam.requiresConfirmation, isTrue);
    expect(lowRam.ram.status, RequirementStatus.insufficient);
  });
}
