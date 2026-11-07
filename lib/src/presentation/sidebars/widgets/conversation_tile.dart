import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/formatters/storage_size_formatter.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final ConversationController conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: conversation,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12, right: 4),
          minLeadingWidth: 20,
          horizontalTitleGap: 8,
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(Icons.chat_bubble_outline, size: 20),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message:
                    'Rozmiar treści rozmowy: ${conversation.contentSizeBytes} B. '
                    'Tytuł, wiadomości i szkic w UTF-8, bez narzutu SQLite.',
                child: Text(
                  '~${StorageSizeFormatter.format(conversation.contentSizeBytes)}',
                  key: ValueKey('conversation-size-${conversation.id}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Usuń rozmowę: ${conversation.title}',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
