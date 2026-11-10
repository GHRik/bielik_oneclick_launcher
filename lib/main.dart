import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:llamadart/llamadart.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/android_app_info.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/android_app_exit_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_exit_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/gpu_inference_adapter.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/compute_routing_llm_repository.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/configuration/database_configuration.dart';
import 'package:bielik_oneclick_launcher/configuration/system_prompt.dart';
import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_app_theme_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/platform_incoming_text_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/platform_speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/system_clipboard_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/llm_settings_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_llm_settings_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_device_resources_repository.dart';
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
  final database = await createAppDatabase();
  final settings = SqliteLlmSettingsRepository(LlmSettingsDataSource(database));
  var activeConfiguration = await settings.load();
  var gpuConfiguration = const GpuConfiguration();
  final metrics = GenerationMetrics();
  const resources = LocalDeviceResourcesRepository(DeviceResourcesDataSource());
  final themeRepository = SqliteAppThemeRepository(database);
  final themePreference = await themeRepository.load();
  final appVersion = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? await AndroidAppInfo.version()
      : null;
  runApp(
    MyApp(
      appVersion: appVersion,
      appExitRepository:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? const AndroidAppExitRepository()
          : const UnavailableAppExitRepository(),
      themeRepository: themeRepository,
      themePreference: themePreference,
      attachmentRepository: LocalAttachmentRepository(),
      incomingTextRepository:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? PlatformIncomingTextRepository()
          : null,
      speechRepository: PlatformSpeechRecognitionRepository(),
      clipboardRepository: const SystemClipboardRepository(),
      onSaveGpuConfiguration: (configuration) =>
          gpuConfiguration = configuration,
      llmConfiguration: activeConfiguration ?? defaultLlmConfiguration,
      onSaveLlmConfiguration: (configuration) async {
        await settings.save(configuration);
        activeConfiguration = configuration;
      },
      deviceResourcesRepository: resources,
      chatRepository: SqliteChatRepository(SqliteChatDataSource(database)),
      modelFilesRepository: LocalModelFilesRepository(ModelFileDataSource()),
      llmRepository: ComputeRoutingLlmRepository(
        createGpu: () => LocalLlmRepository(
          ModelFileDataSource(),
          metrics: metrics,
          systemPrompt: bielikSystemPrompt,
          runtimeAdapter: GpuInferenceAdapter(gpuConfiguration),
          configurationFor: (model) =>
              activeConfiguration ?? llmConfigurationFor(model),
        ),
        cpu: LocalLlmRepository(
          ModelFileDataSource(),
          metrics: metrics,
          systemPrompt: bielikSystemPrompt,
          configurationFor: (model) =>
              activeConfiguration ?? llmConfigurationFor(model),
        ),
      ),
      statisticsRepository: LocalStatisticsRepository(
        const StatisticsDataSource(),
        metrics,
      ),
    ),
  );
}
