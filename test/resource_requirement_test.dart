import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

void main() {
  test('Resource checks distinguish unknown, insufficient and exact thresholds', () {
    for (final available in [null, double.nan, double.infinity, -1.0]) {
      expect(
        ResourceRequirement(requiredGb: 4, availableGb: available).status,
        RequirementStatus.unknown,
      );
    }
    expect(
      const ResourceRequirement(requiredGb: 4, availableGb: 0).status,
      RequirementStatus.insufficient,
    );
    expect(
      const ResourceRequirement(requiredGb: 4, availableGb: 4).status,
      RequirementStatus.sufficient,
    );
  });
}
