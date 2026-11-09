import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';
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
import 'package:bielik_oneclick_launcher/src/domain/repositories/incoming_text_repository.dart';
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
    this.attachmentRepository,
    this.incomingTextRepository,
    this.speechRepository,
    this.clipboardRepository,
  });

  final DeviceResourcesRepository? deviceResourcesRepository;
  final ChatRepository chatRepository;
  final IncomingTextRepository? incomingTextRepository;
  final ModelFilesRepository modelFilesRepository;
  final LlmRepository? llmRepository;
  final LlmConfiguration llmConfiguration;
  final ValueChanged<GpuConfiguration>? onSaveGpuConfiguration;
  final Future<void> Function(LlmConfiguration)? onSaveLlmConfiguration;
  final List<BielikModel> models;
  final List<StatisticSeries> statisticSeries;
  final StatisticsRepository? statisticsRepository;
  final AttachmentRepository? attachmentRepository;
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
  Route<void>? _chatRoute;
  StreamSubscription<String>? _incomingText;
  Future<void> _textImports = Future.value();
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
    _incomingText = widget.incomingTextRepository?.incomingText.listen((text) {
      _textImports = _textImports.then((_) => _importText(text));
    }, onError: (Object error) => _showImportError());
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
    if (state != AppLifecycleState.resumed) {
      unawaited(_chatWorkspace.flush());
    }
  }

  void _showImportError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nie udało się odebrać tekstu. Spróbuj ponownie.'),
      ),
    );
  }

  Future<void> _importText(String text) async {
    if (!mounted) return;
    try {
      final imported = await _chatWorkspace.importText(text);
      if (!mounted) return;
      if (!imported) {
        _showImportError();
        return;
      }
      unawaited(_openChat());
    } catch (_) {
      _showImportError();
    }
  }

  Future<void> _openChat() async {
    if (_chatOpen) {
      final route = _chatRoute;
      if (route != null) {
        Navigator.of(context).popUntil((current) => current == route);
      }
      return;
    }
    setState(() => _chatOpen = true);
    _chatWorkspace.retainModel();
    try {
      if (_chatWorkspace.modelName != _selectedModel.name) {
        await _chatWorkspace.releaseModel();
      }
      if (!mounted) return;
      _chatWorkspace.useModel(
        _selectedModel,
        computeMode: _gpuConfiguration.enabled
            ? LlmComputeMode.gpu
            : LlmComputeMode.cpu,
      );
      final route = MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          workspace: _chatWorkspace,
          attachmentRepository: widget.attachmentRepository,
          speechRepository: widget.speechRepository,
          clipboardRepository: widget.clipboardRepository,
          statisticSeries: widget.statisticSeries,
          statisticsController: _statistics,
        ),
      );
      _chatRoute = route;
      await Navigator.of(context).push(route);
    } finally {
      _chatRoute = null;
      _chatWorkspace.releaseModelWhenIdle();
      if (mounted) {
        setState(() => _chatOpen = false);
        unawaited(_resources.refresh());
      }
    }
  }

  @override
  void dispose() {
    unawaited(_incomingText?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    _statistics?.dispose();
    _resources.dispose();
    _settingsDraft.dispose();
    _chatWorkspace.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LlmSettingsPage(
          draft: _settingsDraft,
          onSave: (configuration) async {
            await widget.onSaveLlmConfiguration?.call(configuration);
            await _chatWorkspace.releaseModel();
          },
          gpuConfiguration: _gpuConfiguration,
          onSaveGpu: (configuration) {
            widget.onSaveGpuConfiguration?.call(configuration);
            _gpuConfiguration = configuration;
          },
        ),
      ),
    );
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
            onPressed: _chatOpen ? null : _openSettings,
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
                    child: Align(
                      alignment: Alignment.topCenter,
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
                              onSettings: _openSettings,
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
