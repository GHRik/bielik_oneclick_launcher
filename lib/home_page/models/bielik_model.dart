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

const bielikModels = [
  BielikModel(
    name: 'Bielik 1.5B v3.0 · Q8',
    diskSpace: 'około 1,7 GB',
    downloadSizeMb: 1700,
    ram: 'około 3–4 GB wolnego RAM; zalecany telefon z 6 GB RAM',
    requiredFreeRamGb: 4,
  ),
  BielikModel(
    name: 'Bielik 4.5B v3.0 · Q8',
    diskSpace: 'około 5,06 GB',
    downloadSizeMb: 5060,
    ram: 'około 6–8 GB wolnego RAM; zalecany telefon z 12 GB RAM',
    requiredFreeRamGb: 8,
  ),
];
