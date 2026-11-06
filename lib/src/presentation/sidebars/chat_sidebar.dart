import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/conversation_list.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/delete_conversation_dialog.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/sidebar_header.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    super.key,
    required this.workspace,
    required this.onNewChat,
    required this.onSelect,
  });

  final ChatWorkspace workspace;
  final VoidCallback onNewChat;
  final ValueChanged<ConversationController> onSelect;

  Future<void> _confirmDelete(
    BuildContext context,
    ConversationController conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConversationDialog(
        conversationTitle: conversation.title,
      ),
    );
    if (confirmed == true && context.mounted) {
      workspace.deleteConversation(conversation);
    }
  }

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
                onDelete: (conversation) => _confirmDelete(context, conversation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
