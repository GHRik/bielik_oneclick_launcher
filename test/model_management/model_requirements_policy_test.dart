import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_requirements.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

void main() {
  group('Model download requirements', () {
    final model = bielikModels.first;
    final unsafeStorage = <String, double?>{
      'missing': null,
      'negative': -1,
      'NaN': double.nan,
      'infinite': double.infinity,
      'insufficient': 0,
    };
    for (final entry in unsafeStorage.entries) {
      test('Requires confirmation when storage is ${entry.key}', () {
        final result = ModelRequirements.evaluate(
          model,
          availableStorageGb: entry.value,
          availableRamGb: 4,
        );

        expect(result.requiresConfirmation, isTrue);
      });
    }

    test(
      'Allows downloading without confirmation when requirements are met',
      () {
        final result = ModelRequirements.evaluate(
          model,
          availableStorageGb: 1.7,
          availableRamGb: 4,
        );

        expect(result.requiresConfirmation, isFalse);
      },
    );

    test('Exposes sufficient storage independently of RAM', () {
      final result = ModelRequirements.evaluate(
        model,
        availableStorageGb: 1.7,
        availableRamGb: 0,
      );

      expect(result.storage.status, RequirementStatus.sufficient);
    });

    test('Exposes sufficient RAM independently of storage', () {
      final result = ModelRequirements.evaluate(
        model,
        availableStorageGb: 0,
        availableRamGb: 4,
      );

      expect(result.ram.status, RequirementStatus.sufficient);
    });

    test('Requires confirmation when RAM is insufficient', () {
      final result = ModelRequirements.evaluate(
        model,
        availableStorageGb: 5,
        availableRamGb: 3,
      );

      expect(result.requiresConfirmation, isTrue);
    });

    test('Exposes insufficient RAM to the view', () {
      final result = ModelRequirements.evaluate(
        model,
        availableStorageGb: 5,
        availableRamGb: 3,
      );

      expect(result.ram.status, RequirementStatus.insufficient);
    });
  });
}
