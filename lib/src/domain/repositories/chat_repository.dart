import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation> createConversation();
  Future<List<ChatMessage>> getMessages(int conversationId);
  Future<ChatMessage> addMessage({
    required int conversationId,
    required String authorId,
    required String text,
    String? conversationTitle,
    bool clearDraft = false,
  });
  Future<void> updateMessage(String id, String text);
  Future<void> saveDraft(int conversationId, String draft);
  Future<void> deleteConversation(int conversationId);
}
