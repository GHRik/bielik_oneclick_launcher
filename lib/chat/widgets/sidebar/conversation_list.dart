import 'package:material_ui/material_ui.dart';

import '../../models/conversation.dart';
import 'conversation_tile.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({
    super.key,
    required this.conversations,
    required this.selected,
    required this.onSelect,
  });

  final List<Conversation> conversations;
  final Conversation selected;
  final ValueChanged<Conversation> onSelect;

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
        );
      },
    );
  }
}
