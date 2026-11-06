import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/conversation_tile.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({
    super.key,
    required this.conversations,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final List<ConversationController> conversations;
  final ConversationController selected;
  final ValueChanged<ConversationController> onSelect;
  final ValueChanged<ConversationController> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationTile(
          key: ValueKey('conversation-${conversation.id}'),
          conversation: conversation,
          selected: conversation == selected,
          onTap: () => onSelect(conversation),
          onDelete: () => onDelete(conversation),
        );
      },
    );
  }
}
