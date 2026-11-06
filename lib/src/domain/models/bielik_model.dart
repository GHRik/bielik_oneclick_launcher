import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class BielikModel {
  const BielikModel({
    required this.name,
    required this.diskSpace,
    required this.downloadSizeMb,
    required this.ram,
    required this.requiredFreeRamGb,
    this.file,
  });

  final ModelFile? file;
  final String name;
  final String diskSpace;
  final double downloadSizeMb;
  final String ram;
  final double requiredFreeRamGb;
}
