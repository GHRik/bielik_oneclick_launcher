import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:llamadart/llamadart.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_chat_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await LlamaLogging.configure(
      level: LlamaLogLevel.info,
      nativeLevel: LlamaLogLevel.info,
    );
  }
  await FlutterModelDownloadDataSource.initialize();
  final database = AppDatabase();
  final metrics = GenerationMetrics();
  runApp(
    MyApp(
      deviceResourcesRepository: const LocalDeviceResourcesRepository(
        DeviceResourcesDataSource(),
      ),
      chatRepository: SqliteChatRepository(SqliteChatDataSource(database)),
      modelFilesRepository: LocalModelFilesRepository(ModelFileDataSource()),
      llmRepository: LocalLlmRepository(
        ModelFileDataSource(),
        metrics: metrics,
        configurationFor: llmConfigurationFor,
      ),
      statisticsRepository: LocalStatisticsRepository(
        const StatisticsDataSource(),
        metrics,
      ),
    ),
  );
}
