import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
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
  });

  final ChatWorkspace workspace;
  final List<StatisticSeries> statisticSeries;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _closeSidebar() {
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
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsPage(series: widget.statisticSeries),
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
      listenable: widget.workspace,
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
                            FocusManager.instance.primaryFocus?.unfocus();
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        ),
                      ],
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Czat'),
                  if (widget.workspace.modelName != null)
                    Text(widget.workspace.modelName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              actions: [
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
                : Drawer(width: 280, child: ChatSidebar(
                    workspace: widget.workspace,
                    onNewChat: _newChat,
                    onSelect: _selectConversation,
                  )),
            body: Row(
              children: [
                if (showSidebar) ...[
                  SizedBox(width: 280, child: ChatSidebar(
                    workspace: widget.workspace,
                    onNewChat: _newChat,
                    onSelect: _selectConversation,
                  )),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(
                              widget.workspace.generationStatus,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            )),
                            TextButton.icon(
                              onPressed: widget.workspace.stopGeneration,
                              icon: const Icon(Icons.stop),
                              label: const Text('Zatrzymaj'),
                            ),
                          ]),
                        ),
                      Expanded(
                        child: ConversationView(
                          conversation: widget.workspace.selected,
                          onMessageSend: widget.workspace.sendMessage,
                          sending: widget.workspace.sending || widget.workspace.busy,
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
