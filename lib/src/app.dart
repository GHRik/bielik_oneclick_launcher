import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/configured_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.chatRepository,
    required this.modelFilesRepository,
    this.llmRepository,
    this.llmConfiguration = defaultLlmConfiguration,
    this.onSaveLlmConfiguration,
    this.onSaveGpuConfiguration,
    this.deviceResourcesRepository,
    this.modelRepository = const ConfiguredModelCatalogRepository(bielikModels),
    this.statisticsRepository,
    this.speechRepository,
  });

  final DeviceResourcesRepository? deviceResourcesRepository;
  final ChatRepository chatRepository;
  final ModelFilesRepository modelFilesRepository;
  final LlmRepository? llmRepository;
  final LlmConfiguration llmConfiguration;
  final ValueChanged<GpuConfiguration>? onSaveGpuConfiguration;
  final Future<void> Function(LlmConfiguration)? onSaveLlmConfiguration;
  final ModelCatalogRepository modelRepository;
  final StatisticsRepository? statisticsRepository;
  final SpeechRecognitionRepository? speechRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bielik',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: HomePage(
        deviceResourcesRepository: deviceResourcesRepository,
        chatRepository: chatRepository,
        speechRepository: speechRepository,
        modelFilesRepository: modelFilesRepository,
        llmRepository: llmRepository,
        llmConfiguration: llmConfiguration,
        onSaveLlmConfiguration: onSaveLlmConfiguration,
        onSaveGpuConfiguration: onSaveGpuConfiguration,
        models: modelRepository.getModels(),
        statisticSeries: statisticsRepository?.getSeries() ?? const [],
        statisticsRepository: statisticsRepository,
      ),
    );
  }
}
