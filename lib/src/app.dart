import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/preview_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/preview_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.chatRepository,
    required this.modelFilesRepository,
    this.modelRepository = const PreviewModelCatalogRepository(),
    this.statisticsRepository = const PreviewStatisticsRepository(),
  });

  final ChatRepository chatRepository;
  final ModelFilesRepository modelFilesRepository;
  final ModelCatalogRepository modelRepository;
  final StatisticsRepository statisticsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bielik',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: HomePage(
        chatRepository: chatRepository,
        modelFilesRepository: modelFilesRepository,
        models: modelRepository.getModels(),
        statisticSeries: statisticsRepository.getSeries(),
      ),
    );
  }
}
