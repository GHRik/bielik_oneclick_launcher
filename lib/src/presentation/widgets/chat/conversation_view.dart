import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/message_with_actions.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/assistant_markdown_message.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.conversation,
    required this.onMessageSend,
    this.sending = false,
  });

  final ConversationController conversation;
  final ValueChanged<String> onMessageSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Chat(
      key: ValueKey('chat-${conversation.id}'),
      chatController: conversation.controller,
      currentUserId: ChatAuthors.user,
      onMessageSend: onMessageSend,
      resolveUser: (id) async =>
          User(id: id, name: id == ChatAuthors.user ? 'Ty' : 'Bielik'),
      builders: Builders(
        textMessageBuilder:
            (
              context,
              message,
              index, {
              required bool isSentByMe,
              MessageGroupStatus? groupStatus,
            }) => isSentByMe
            ? MessageWithActions(
                messageId: message.id,
                child: SelectionArea(
                  child: SimpleTextMessage(message: message, index: index),
                ),
              )
            : AssistantMarkdownMessage(message: message),
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
          inputClearMode: InputClearMode.never,
          sendButtonDisabled: sending,
          sendIcon: const Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
        ),
      ),
    );
  }
}
