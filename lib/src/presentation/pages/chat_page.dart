import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/statistics_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/chat_sidebar.dart';
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
              title: const Text('Czat'),
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
                  child: ConversationView(
                    conversation: widget.workspace.selected,
                    onMessageSend: widget.workspace.sendMessage,
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
