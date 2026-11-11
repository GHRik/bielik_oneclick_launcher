import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/text_attachment_codec.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';

class SqliteChatRepository implements ChatRepository {
  const SqliteChatRepository(this.dataSource);

  final SqliteChatDataSource dataSource;

  Conversation _conversation(Map<String, Object?> row) => Conversation(
    id: row['id']! as int,
    title: row['title']! as String,
    draft: Conversation.clampDraft(row['draft']! as String),
    draftAttachment: TextAttachmentCodec.decode(row['draft_attachment']),
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
    attachment: TextAttachmentCodec.decode(row['attachment']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ),
  );

  @override
  Future<List<Conversation>> getConversations() async =>
      (await dataSource.getConversations(
        maxDraftLength: Conversation.maxDraftLength,
      )).map(_conversation).toList();

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
    TextAttachment? attachment,
  }) async => _message(
    await dataSource.addMessage(
      conversationId: conversationId,
      authorId: authorId,
      text: text,
      conversationTitle: conversationTitle,
      clearDraft: clearDraft,
      attachment: TextAttachmentCodec.encode(attachment),
      timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
    ),
  );

  @override
  Future<void> updateMessage(String id, String text) =>
      dataSource.updateMessage(id, text);

  @override
  Future<void> saveDraft(int conversationId, String draft) =>
      dataSource.saveDraft(conversationId, Conversation.clampDraft(draft));

  @override
  Future<void> saveDraftAttachment(
    int conversationId,
    TextAttachment? attachment,
  ) => dataSource.saveDraftAttachment(
    conversationId,
    TextAttachmentCodec.encode(attachment),
  );

  @override
  Future<void> markConversationUsed(int conversationId) =>
      dataSource.markConversationUsed(conversationId);

  @override
  Future<void> deleteConversation(int conversationId) =>
      dataSource.deleteConversation(conversationId);
}
