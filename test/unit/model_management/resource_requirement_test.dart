import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

void main() {
  group('Resource availability classification', () {
    final invalidValues = <String, double?>{
      'missing': null,
      'NaN': double.nan,
      'infinite': double.infinity,
      'negative': -1,
    };
    for (final entry in invalidValues.entries) {
      test('Treats ${entry.key} availability as unknown', () {
        expect(
          ResourceRequirement(requiredGb: 4, availableGb: entry.value).status,
          RequirementStatus.unknown,
        );
      });
    }

    test('Treats zero availability as insufficient', () {
      expect(
        const ResourceRequirement(requiredGb: 4, availableGb: 0).status,
        RequirementStatus.insufficient,
      );
    });

    test('Accepts availability equal to the requirement', () {
      expect(
        const ResourceRequirement(requiredGb: 4, availableGb: 4).status,
        RequirementStatus.sufficient,
      );
    });
  });
}
