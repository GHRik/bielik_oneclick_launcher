import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';

abstract interface class ModelCatalogRepository {
  List<BielikModel> getModels();
}
