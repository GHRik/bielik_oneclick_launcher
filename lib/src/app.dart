import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_update_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_exit_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/app_exit_notice.dart';

import 'package:bielik_oneclick_launcher/src/presentation/theme/landing_page_theme.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_theme_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/app_theme_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/app_theme_scope.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/configured_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/incoming_text_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.chatRepository,
    required this.modelFilesRepository,
    this.llmRepository,
    this.appVersion,
    this.appUpdateRepository,
    this.llmConfiguration = defaultLlmConfiguration,
    this.onSaveLlmConfiguration,
    this.onSaveGpuConfiguration,
    this.deviceResourcesRepository,
    this.modelRepository = const ConfiguredModelCatalogRepository(bielikModels),
    this.statisticsRepository,
    this.attachmentRepository,
    this.incomingTextRepository,
    this.speechRepository,
    this.clipboardRepository,
    this.themePreference = AppThemePreference.system,
    this.themeRepository,
    this.appExitRepository = const UnavailableAppExitRepository(),
  });

  final DeviceResourcesRepository? deviceResourcesRepository;
  final ChatRepository chatRepository;
  final IncomingTextRepository? incomingTextRepository;
  final ModelFilesRepository modelFilesRepository;
  final LlmRepository? llmRepository;
  final AppVersion? appVersion;
  final AppUpdateRepository? appUpdateRepository;
  final LlmConfiguration llmConfiguration;
  final ValueChanged<GpuConfiguration>? onSaveGpuConfiguration;
  final Future<void> Function(LlmConfiguration)? onSaveLlmConfiguration;
  final ModelCatalogRepository modelRepository;
  final StatisticsRepository? statisticsRepository;
  final AttachmentRepository? attachmentRepository;
  final SpeechRecognitionRepository? speechRepository;
  final ClipboardRepository? clipboardRepository;
  final AppThemePreference themePreference;
  final AppThemeRepository? themeRepository;
  final AppExitRepository appExitRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _theme = AppThemeController(
    initial: widget.themePreference,
    repository: widget.themeRepository,
  );

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp(
          title: 'Bielik',
          theme: landingPageTheme(Brightness.light),
          darkTheme: landingPageTheme(Brightness.dark),
          themeMode: _theme.mode,
          home: AppExitNotice(
            repository: widget.appExitRepository,
            child: HomePage(
              appVersion: widget.appVersion,
              appUpdateRepository: widget.appUpdateRepository,
              deviceResourcesRepository: widget.deviceResourcesRepository,
              chatRepository: widget.chatRepository,
              attachmentRepository: widget.attachmentRepository,
              incomingTextRepository: widget.incomingTextRepository,
              speechRepository: widget.speechRepository,
              clipboardRepository: widget.clipboardRepository,
              modelFilesRepository: widget.modelFilesRepository,
              llmRepository: widget.llmRepository,
              llmConfiguration: widget.llmConfiguration,
              onSaveLlmConfiguration: widget.onSaveLlmConfiguration,
              onSaveGpuConfiguration: widget.onSaveGpuConfiguration,
              models: widget.modelRepository.getModels(),
              statisticSeries:
                  widget.statisticsRepository?.getSeries() ?? const [],
              statisticsRepository: widget.statisticsRepository,
            ),
          ),
        ),
      ),
    );
  }
}
