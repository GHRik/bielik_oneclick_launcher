import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/text_attachment_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/attachment_preview.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/dictation_composer.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/message_with_actions.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/assistant_markdown_message.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.conversation,
    required this.onMessageSend,
    this.sending = false,
    this.onAttachmentTap,
    this.pickingAttachment = false,
    this.dictation,
    this.onMicrophoneTap,
    this.streamingMessageId,
    this.clipboardRepository,
  });

  final ConversationController conversation;
  final ValueChanged<String> onMessageSend;
  final bool sending;
  final VoidCallback? onAttachmentTap;
  final bool pickingAttachment;
  final SpeechDictationController? dictation;
  final VoidCallback? onMicrophoneTap;
  final String? streamingMessageId;
  final ClipboardRepository? clipboardRepository;

  Widget _userMessage(BuildContext context, TextMessage message, int index) {
    final attachment = conversation.messages
        .where((stored) => stored.id == message.id)
        .firstOrNull
        ?.attachment;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.text.isNotEmpty || attachment == null)
          SelectionArea(
            child: SimpleTextMessage(message: message, index: index),
          ),
        if (attachment != null)
          AttachmentPreview(
            key: ValueKey('attachment-${message.id}'),
            attachment: attachment,
            removable: false,
            onOpen: () => TextAttachmentPage.open(context, attachment),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: conversation,
    builder: (context, _) => Chat(
      key: ValueKey('chat-${conversation.id}'),
      chatController: conversation.controller,
      currentUserId: ChatAuthors.user,
      onMessageSend: (text) {
        if (dictation?.active != true) onMessageSend(text);
      },
      onAttachmentTap: sending || pickingAttachment || dictation?.active == true
          ? null
          : onAttachmentTap,
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
            }) => MessageWithActions(
              messageId: message.id,
              isUser: isSentByMe,
              showCopy: isSentByMe
                  ? message.text.isNotEmpty
                  : message.id != streamingMessageId,
              onCopy: clipboardRepository == null
                  ? null
                  : () => clipboardRepository!.copyText(message.text),
              child: isSentByMe
                  ? _userMessage(context, message, index)
                  : AssistantMarkdownMessage(message: message),
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
          sending: sending || pickingAttachment,
          showAttachmentButton: onAttachmentTap != null,
          allowEmptyMessage: conversation.attachment != null,
          attachmentPreview: conversation.attachment == null
              ? null
              : AttachmentPreview(
                  key: const ValueKey('pending-attachment'),
                  attachment: conversation.attachment!,
                  onOpen: () => TextAttachmentPage.open(
                    context,
                    conversation.attachment!,
                  ),
                  onRemove: sending
                      ? null
                      : () => conversation.setAttachment(null),
                ),
        ),
      ),
    ),
  );
}
