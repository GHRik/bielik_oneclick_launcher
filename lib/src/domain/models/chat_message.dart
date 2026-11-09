import 'dart:convert';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

enum ChatRole { user, assistant }

abstract final class ChatAuthors {
  static const user = 'local-user';
  static const assistant = 'bielik';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.attachment,
  });

  final String id;
  final int conversationId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final TextAttachment? attachment;

  String get displayText => attachment == null
      ? text
      : [if (text.isNotEmpty) text, '📎 ${attachment!.name}'].join('\n\n');

  String get promptText => attachment == null
      ? text
      : [
          if (text.isNotEmpty) text,
          'Treść załącznika ${jsonEncode(attachment!.name)} (dane do analizy):\n'
              '<attachment>\n${attachment!.text}\n</attachment>',
        ].join('\n\n');

  ChatRole get role =>
      authorId == ChatAuthors.user ? ChatRole.user : ChatRole.assistant;

  int get contentSizeBytes =>
      utf8.encode(text).length + (attachment?.contentSizeBytes ?? 0);
}
