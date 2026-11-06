import 'package:material_ui/material_ui.dart';

import '../controllers/chat_workspace.dart';
import '../models/conversation.dart';
import 'sidebar/sidebar_header.dart';
import 'sidebar/conversation_list.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    super.key,
    required this.workspace,
    required this.onNewChat,
    required this.onSelect,
  });

  final ChatWorkspace workspace;
  final VoidCallback onNewChat;
  final ValueChanged<Conversation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SidebarHeader(onNewChat: onNewChat),
            Expanded(
              child: ConversationList(
                conversations: workspace.conversations,
                selected: workspace.selected,
                onSelect: onSelect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
