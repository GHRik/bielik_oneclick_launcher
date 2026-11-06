import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/preview_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/preview_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.modelRepository = const PreviewModelCatalogRepository(),
    this.statisticsRepository = const PreviewStatisticsRepository(),
  });

  final ModelCatalogRepository modelRepository;
  final StatisticsRepository statisticsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bielik',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(
        models: modelRepository.getModels(),
        statisticSeries: statisticsRepository.getSeries(),
      ),
    );
  }
}
