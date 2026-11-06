import 'package:bielik_oneclick_launcher/src/data/datasources/preview_model_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';

class PreviewModelCatalogRepository implements ModelCatalogRepository {
  const PreviewModelCatalogRepository({
    this.dataSource = const PreviewModelDataSource(),
  });

  final PreviewModelDataSource dataSource;

  @override
  List<BielikModel> getModels() => List.unmodifiable(dataSource.getModels());
}
