class BielikModel {
  const BielikModel({
    required this.name,
    required this.diskSpace,
    required this.ram,
  });

  final String name;
  final String diskSpace;
  final String ram;
}

const bielikModels = [
  BielikModel(
    name: 'Bielik 1.5B v3.0 · Q8',
    diskSpace: 'około 1,7 GB',
    ram: 'około 3–4 GB wolnego RAM; zalecany telefon z 6 GB RAM',
  ),
  BielikModel(
    name: 'Bielik 4.5B v3.0 · Q8',
    diskSpace: 'około 5,06 GB',
    ram: 'około 6–8 GB wolnego RAM; zalecany telefon z 12 GB RAM',
  ),
];
