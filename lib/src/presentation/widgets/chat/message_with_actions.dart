import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/message_copy_button.dart';

class MessageWithActions extends StatelessWidget {
  const MessageWithActions({
    super.key,
    required this.messageId,
    required this.child,
    this.onCopy,
    this.isUser = true,
    this.showCopy = true,
  });

  final String messageId;
  final Widget child;
  final Future<void> Function()? onCopy;
  final bool isUser;
  final bool showCopy;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      child,
      if (showCopy)
        MessageCopyButton(
          key: ValueKey('copy-message-$messageId'),
          onCopy: onCopy,
        ),
    ],
  );
}
