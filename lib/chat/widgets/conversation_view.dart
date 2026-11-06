import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/chat/models/conversation.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.conversation,
    required this.onMessageSend,
  });

  final Conversation conversation;
  final ValueChanged<String> onMessageSend;

  @override
  Widget build(BuildContext context) {
    return Chat(
      key: ValueKey('chat-${conversation.id}'),
      chatController: conversation.controller,
      currentUserId: 'local-user',
      onMessageSend: onMessageSend,
      resolveUser: (id) async => User(id: id, name: 'Ty'),
      builders: Builders(
        emptyChatListBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'W czym mogę pomóc?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        composerBuilder: (context) => Composer(
          key: ValueKey('composer-${conversation.id}'),
          textEditingController: conversation.draft,
          hintText: 'Napisz wiadomość…',
          attachmentIcon: null,
          sendIcon: const Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
        ),
      ),
    );
  }
}
