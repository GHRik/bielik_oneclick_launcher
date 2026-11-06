import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';

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

class PreviewModelDataSource {
  const PreviewModelDataSource();

  List<BielikModel> getModels() => bielikModels;
}
