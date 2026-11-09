import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/dictation_composer.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/message_with_actions.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/assistant_markdown_message.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.conversation,
    required this.onMessageSend,
    this.sending = false,
    this.dictation,
    this.onMicrophoneTap,
    this.streamingMessageId,
    this.clipboardRepository,
  });

  final ConversationController conversation;
  final ValueChanged<String> onMessageSend;
  final bool sending;
  final SpeechDictationController? dictation;
  final VoidCallback? onMicrophoneTap;
  final String? streamingMessageId;
  final ClipboardRepository? clipboardRepository;

  @override
  Widget build(BuildContext context) {
    return Chat(
      key: ValueKey('chat-${conversation.id}'),
      chatController: conversation.controller,
      currentUserId: ChatAuthors.user,
      onMessageSend: (text) {
        if (dictation?.active != true) onMessageSend(text);
      },
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
                onCopy: clipboardRepository == null
                    ? null
                    : () => clipboardRepository!.copyText(message.text),
                child: SelectionArea(
                  child: SimpleTextMessage(message: message, index: index),
                ),
              )
            : MessageWithActions(
                messageId: message.id,
                isUser: false,
                showCopy: message.id != streamingMessageId,
                onCopy: clipboardRepository == null
                    ? null
                    : () => clipboardRepository!.copyText(message.text),
                child: AssistantMarkdownMessage(message: message),
              ),
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
        composerBuilder: (context) => DictationComposer(
          key: ValueKey('composer-${conversation.id}'),
          draft: conversation.draft,
          dictation: dictation,
          onMicrophoneTap: onMicrophoneTap,
          sending: sending,
        ),
      ),
    );
  }
}
