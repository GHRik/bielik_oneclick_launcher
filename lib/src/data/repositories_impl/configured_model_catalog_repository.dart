import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';

class ConfiguredModelCatalogRepository implements ModelCatalogRepository {
  const ConfiguredModelCatalogRepository(this.models);

  final List<BielikModel> models;

  @override
  List<BielikModel> getModels() => List.unmodifiable(models);
}
