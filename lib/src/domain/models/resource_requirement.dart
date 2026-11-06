enum RequirementStatus { unknown, insufficient, sufficient }

class ResourceRequirement {
  const ResourceRequirement({required this.requiredGb, this.availableGb});

  final double requiredGb;
  final double? availableGb;

  RequirementStatus get status {
    final available = availableGb;
    if (available == null || !available.isFinite || available < 0) {
      return RequirementStatus.unknown;
    }
    return available >= requiredGb
        ? RequirementStatus.sufficient
        : RequirementStatus.insufficient;
  }
}
