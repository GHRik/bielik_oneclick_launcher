class BielikModel {
  const BielikModel({
    required this.name,
    required this.diskSpace,
    required this.downloadSizeMb,
    required this.ram,
    required this.requiredFreeRamGb,
  });

  final String name;
  final String diskSpace;
  final double downloadSizeMb;
  final String ram;
  final double requiredFreeRamGb;
}
