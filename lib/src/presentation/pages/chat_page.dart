import 'dart:async';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_memory_warning_button.dart';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_model_header.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/context_usage_indicator.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/statistics_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/statistics_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/chat_sidebar.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_history_status.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/conversation_view.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.workspace,
    required this.statisticSeries,
    this.statisticsController,
    this.attachmentRepository,
    this.speechRepository,
    this.clipboardRepository,
  });

  final ChatWorkspace workspace;
  final List<StatisticSeries> statisticSeries;
  final StatisticsController? statisticsController;
  final AttachmentRepository? attachmentRepository;
  final SpeechRecognitionRepository? speechRepository;
  final ClipboardRepository? clipboardRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final SpeechDictationController? _dictation =
      widget.speechRepository == null
      ? null
      : SpeechDictationController(widget.speechRepository!);
  late final _changes = Listenable.merge([widget.workspace, ?_dictation]);
  ConversationController? _speechTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.workspace.addListener(_onWorkspaceChanged);
  }

  void _onWorkspaceChanged() {
    if (_dictation?.active == true &&
        (!widget.workspace.ready ||
            widget.workspace.selected != _speechTarget ||
            widget.workspace.sending ||
            widget.workspace.busy)) {
      unawaited(_dictation!.cancel());
    }
  }

  void _cancelDictation() {
    if (_dictation?.active == true) unawaited(_dictation!.cancel());
  }

  void _toggleDictation() {
    _speechTarget = widget.workspace.selected;
    unawaited(_dictation?.toggle(_speechTarget!.draft));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive && _dictation?.starting != true)) {
      _cancelDictation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.workspace.removeListener(_onWorkspaceChanged);
    _dictation?.dispose();
    super.dispose();
  }

  void _closeSidebar() {
    _cancelDictation();
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState!.closeDrawer();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _newChat() {
    _closeSidebar();
    widget.workspace.newChat();
  }

  void _openStatistics() {
    _cancelDictation();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsPage(
          series: widget.statisticSeries,
          controller: widget.statisticsController,
        ),
      ),
    );
  }

  void _selectConversation(ConversationController conversation) {
    _closeSidebar();
    widget.workspace.selectConversation(conversation);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          if (!widget.workspace.ready) {
            return Scaffold(
              appBar: AppBar(title: const Text('Czat')),
              body: ChatHistoryStatus(
                loading: widget.workspace.loading || widget.workspace.busy,
                error: widget.workspace.error,
                onRetry: widget.workspace.initialize,
              ),
            );
          }
          final showSidebar = constraints.maxWidth >= 840;
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              leadingWidth: showSidebar ? null : 104,
              leading: showSidebar
                  ? const BackButton()
                  : Row(
                      children: [
                        const BackButton(),
                        IconButton(
                          tooltip: 'Rozmowy',
                          onPressed: () {
                            _cancelDictation();
                            FocusManager.instance.primaryFocus?.unfocus();
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        ),
                      ],
                    ),
              title: widget.workspace.modelName == null
                  ? const Text('Czat')
                  : ChatModelHeader(
                      status: widget.workspace.computeStatus,
                      modelName: widget.workspace.modelName!,
                    ),
              actions: [
                ContextUsageIndicator(
                  key: ValueKey('context-${widget.workspace.selected.id}'),
                  usage: widget.workspace.contextUsage,
                  showOmissionWarning:
                      widget.workspace.hasUnseenContextOmissions,
                  onOmissionsAcknowledged:
                      widget.workspace.acknowledgeContextOmissions,
                ),
                IconButton(
                  tooltip: 'Statystyki',
                  onPressed: _openStatistics,
                  icon: const Icon(Icons.bar_chart),
                ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: showSidebar
                ? null
                : Drawer(
                    width: 280,
                    child: ChatSidebar(
                      workspace: widget.workspace,
                      onNewChat: _newChat,
                      onSelect: _selectConversation,
                    ),
                  ),
            body: Row(
              children: [
                if (showSidebar) ...[
                  SizedBox(
                    width: 280,
                    child: ChatSidebar(
                      workspace: widget.workspace,
                      onNewChat: _newChat,
                      onSelect: _selectConversation,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Column(
                    children: [
                      if (widget.workspace.error != null)
                        MaterialBanner(
                          content: Text(widget.workspace.error!),
                          actions: [
                            TextButton(
                              onPressed: widget.workspace.dismissError,
                              child: const Text('Zamknij'),
                            ),
                          ],
                        ),
                      if (widget.workspace.sending)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.workspace.generationStatus,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.workspace.showMemoryWarning)
                                      ModelMemoryWarningButton(
                                        modelName: widget.workspace.modelName!,
                                      ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: widget.workspace.stopGeneration,
                                icon: const Icon(Icons.stop),
                                label: const Text('Zatrzymaj'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ConversationView(
                          conversation: widget.workspace.selected,
                          onAttachmentTap: widget.attachmentRepository == null
                              ? null
                              : () => widget.workspace.pickAttachment(
                                  widget.attachmentRepository!,
                                ),
                          pickingAttachment: widget.workspace.pickingAttachment,
                          dictation: _dictation,
                          onMicrophoneTap: _toggleDictation,
                          streamingMessageId:
                              widget.workspace.streamingMessageId,
                          clipboardRepository: widget.clipboardRepository,
                          onMessageSend: widget.workspace.sendMessage,
                          onTextAction: widget.workspace.sendTextAction,
                          sending:
                              widget.workspace.sending || widget.workspace.busy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
