import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final Map<int, Conversation> _conversations = {};
  final List<ChatMessage> _messages = [];
  final Map<int, int> _usageOrder = {};
  int _usageSequence = 0;
  int _nextConversationId = 1;
  int _nextMessageId = 1;
  bool failRead = false;
  bool failCreate = false;
  bool failSend = false;
  bool failDelete = false;
  Completer<void>? sendGate;
  Completer<void>? sendStarted;

  @override
  Future<List<Conversation>> getConversations() async {
    if (failRead) throw StateError('Read failed');
    return _conversations.values.toList()
      ..sort((a, b) => _usageOrder[b.id]!.compareTo(_usageOrder[a.id]!));
  }

  @override
  Future<Conversation> createConversation() async {
    if (failCreate) throw StateError('Create failed');
    final now = DateTime.now().toUtc();
    final conversation = Conversation(
      id: _nextConversationId++,
      createdAt: now,
      updatedAt: now,
    );
    _conversations[conversation.id] = conversation;
    _usageOrder[conversation.id] = ++_usageSequence;
    return conversation;
  }

  @override
  Future<List<ChatMessage>> getMessages(int conversationId) async => _messages
      .where((message) => message.conversationId == conversationId)
      .toList();

  @override
  Future<ChatMessage> addMessage({
    required int conversationId,
    required String authorId,
    required String text,
    String? conversationTitle,
    bool clearDraft = false,
  }) async {
    if (sendStarted != null && !sendStarted!.isCompleted) {
      sendStarted!.complete();
    }
    await sendGate?.future;
    if (failSend) throw StateError('Send failed');
    final conversation = _conversations[conversationId]!;
    final message = ChatMessage(
      id: 'test-message-${_nextMessageId++}',
      conversationId: conversationId,
      authorId: authorId,
      text: text,
      createdAt: DateTime.now().toUtc(),
    );
    _messages.add(message);
    _conversations[conversationId] = conversation.copyWith(
      title: conversationTitle,
      draft: clearDraft ? '' : conversation.draft,
      updatedAt: message.createdAt,
    );
    return message;
  }

  @override
  Future<void> updateMessage(String id, String text) async {
    if (failSend) throw StateError('Send failed');
    final index = _messages.indexWhere((message) => message.id == id);
    final old = _messages[index];
    _messages[index] = ChatMessage(
      id: old.id,
      conversationId: old.conversationId,
      authorId: old.authorId,
      text: text,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<void> saveDraft(int conversationId, String draft) async {
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _conversations[conversationId] = conversation.copyWith(draft: draft);
    }
  }

  @override
  Future<void> markConversationUsed(int conversationId) async {
    if (!_conversations.containsKey(conversationId)) {
      throw StateError('Conversation not found');
    }
    _usageOrder[conversationId] = ++_usageSequence;
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    if (failDelete) throw StateError('Delete failed');
    _conversations.remove(conversationId);
    _messages.removeWhere(
      (message) => message.conversationId == conversationId,
    );
  }
}
