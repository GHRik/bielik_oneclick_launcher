import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/statistics_controller.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/device_resources_controller.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/llm_settings_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.models,
    required this.llmConfiguration,
    this.onSaveLlmConfiguration,
    this.onSaveGpuConfiguration,
    required this.modelFilesRepository,
    this.llmRepository,
    this.deviceResourcesRepository,
    required this.chatRepository,
    required this.statisticSeries,
    this.statisticsRepository,
    this.speechRepository,
    this.clipboardRepository,
  });

  final DeviceResourcesRepository? deviceResourcesRepository;
  final ChatRepository chatRepository;
  final ModelFilesRepository modelFilesRepository;
  final LlmRepository? llmRepository;
  final LlmConfiguration llmConfiguration;
  final ValueChanged<GpuConfiguration>? onSaveGpuConfiguration;
  final Future<void> Function(LlmConfiguration)? onSaveLlmConfiguration;
  final List<BielikModel> models;
  final List<StatisticSeries> statisticSeries;
  final StatisticsRepository? statisticsRepository;
  final SpeechRecognitionRepository? speechRepository;
  final ClipboardRepository? clipboardRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final ChatWorkspace _chatWorkspace;
  StatisticsController? _statistics;
  late final _resources = DeviceResourcesController(
    widget.deviceResourcesRepository,
  );
  late BielikModel _selectedModel = widget.models.first;
  late final _settingsDraft = LlmSettingsDraft(widget.llmConfiguration);
  bool _chatOpen = false;
  GpuConfiguration _gpuConfiguration = const GpuConfiguration();

  @override
  void initState() {
    super.initState();
    _chatWorkspace = ChatWorkspace(
      widget.chatRepository,
      llmRepository: widget.llmRepository,
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(_chatWorkspace.initialize());
    unawaited(_resources.refresh());
    final repository = widget.statisticsRepository;
    if (repository != null) {
      _statistics = StatisticsController(repository)..start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resources.refresh());
      _statistics?.start();
    } else {
      _statistics?.pause();
    }
    if (state == AppLifecycleState.paused) {
      unawaited(_chatWorkspace.releaseModel());
    }
    if (state != AppLifecycleState.resumed) {
      unawaited(_chatWorkspace.flush());
    }
  }

  Future<void> _openChat() async {
    if (_chatOpen) return;
    setState(() => _chatOpen = true);
    try {
      await _chatWorkspace.releaseModel();
      if (!mounted) return;
      _chatWorkspace.useModel(
        _selectedModel,
        computeMode: _gpuConfiguration.enabled
            ? LlmComputeMode.gpu
            : LlmComputeMode.cpu,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            workspace: _chatWorkspace,
            speechRepository: widget.speechRepository,
            clipboardRepository: widget.clipboardRepository,
            statisticSeries: widget.statisticSeries,
            statisticsController: _statistics,
          ),
        ),
      );
    } finally {
      await _chatWorkspace.releaseModel();
      if (mounted) {
        setState(() => _chatOpen = false);
        unawaited(_resources.refresh());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statistics?.dispose();
    _resources.dispose();
    _settingsDraft.dispose();
    _chatWorkspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bielik'),
        actions: [
          IconButton(
            tooltip: 'Konfiguracja LLM',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _chatOpen
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LlmSettingsPage(
                        draft: _settingsDraft,
                        onSave: widget.onSaveLlmConfiguration,
                        gpuConfiguration: _gpuConfiguration,
                        onSaveGpu: (configuration) {
                          widget.onSaveGpuConfiguration?.call(configuration);
                          _gpuConfiguration = configuration;
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: AbsorbPointer(
                          absorbing: _chatOpen,
                          child: ListenableBuilder(
                            listenable: _resources,
                            builder: (context, _) => ModelManagementPanel(
                              models: widget.models,
                              repository: widget.modelFilesRepository,
                              onModelSelected: (model) =>
                                  _selectedModel = model,
                              availableStorageGb:
                                  _resources.resources.freeStorageGb,
                              availableRamGb:
                                  _resources.resources.availableRamGb,
                              totalRamGb: _resources.resources.totalRamGb,
                              onResourcesChanged: _resources.refresh,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _chatOpen ? null : _openChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Otwórz czat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
