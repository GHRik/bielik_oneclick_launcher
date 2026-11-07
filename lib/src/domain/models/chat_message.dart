import 'dart:convert';

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
  });

  final String id;
  final int conversationId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  ChatRole get role =>
      authorId == ChatAuthors.user ? ChatRole.user : ChatRole.assistant;

  int get contentSizeBytes => utf8.encode(text).length;
}
