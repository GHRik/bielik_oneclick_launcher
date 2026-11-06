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
}
