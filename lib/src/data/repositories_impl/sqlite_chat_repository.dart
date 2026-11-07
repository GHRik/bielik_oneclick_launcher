import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';

class SqliteChatRepository implements ChatRepository {
  const SqliteChatRepository(this.dataSource);

  final SqliteChatDataSource dataSource;

  Conversation _conversation(Map<String, Object?> row) => Conversation(
    id: row['id']! as int,
    title: row['title']! as String,
    draft: row['draft']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      row['updated_at']! as int,
      isUtc: true,
    ),
  );

  ChatMessage _message(Map<String, Object?> row) => ChatMessage(
    id: row['id']! as String,
    conversationId: row['conversation_id']! as int,
    authorId: row['author_id']! as String,
    text: row['text']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ),
  );

  @override
  Future<List<Conversation>> getConversations() async =>
      (await dataSource.getConversations()).map(_conversation).toList();

  @override
  Future<Conversation> createConversation() async => _conversation(
    await dataSource.createConversation(
      title: 'Nowa rozmowa',
      timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
    ),
  );

  @override
  Future<List<ChatMessage>> getMessages(int conversationId) async =>
      (await dataSource.getMessages(conversationId)).map(_message).toList();

  @override
  Future<ChatMessage> addMessage({
    required int conversationId,
    required String authorId,
    required String text,
    String? conversationTitle,
    bool clearDraft = false,
  }) async => _message(
    await dataSource.addMessage(
      conversationId: conversationId,
      authorId: authorId,
      text: text,
      conversationTitle: conversationTitle,
      clearDraft: clearDraft,
      timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
    ),
  );

  @override
  Future<void> updateMessage(String id, String text) =>
      dataSource.updateMessage(id, text);

  @override
  Future<void> saveDraft(int conversationId, String draft) =>
      dataSource.saveDraft(conversationId, draft);

  @override
  Future<void> deleteConversation(int conversationId) =>
      dataSource.deleteConversation(conversationId);
}
