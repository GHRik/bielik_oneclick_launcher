import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/configured_model_catalog_repository.dart';

void main() {
  group('ConfiguredModelCatalogRepository', () {
    test('getModels returns the catalog supplied to the constructor', () {
      expect(
        const ConfiguredModelCatalogRepository(bielikModels).getModels(),
        bielikModels,
      );
    });
  });
}
