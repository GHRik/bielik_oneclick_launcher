import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_service.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';

class _Llm implements LlmRepository {
  List<ChatMessage>? history;
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
  }) {
    this.history = history;
    return Stream.fromIterable(['First', ' and second']);
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {}
}

void main() {
  group('Chat service message submission', () {
    late _ChatRepository repository;
    late _Llm llm;
    late ChatService service;
    late int conversationId;
    const model = ModelFile(
      name: 'test.gguf',
      url: 'https://example.com',
      sizeBytes: 1,
      sha256: '',
    );

    setUp(() async {
      repository = _ChatRepository();
      conversationId = (await repository.createConversation()).id;
      llm = _Llm();
      service = ChatService(repository, llmRepository: llm);
    });

    Future<void> send({void Function(ChatUpdate)? onUpdate}) => service.send(
      conversationId: conversationId,
      text: '  Question  ',
      history: [],
      model: model,
      onUpdate: onUpdate ?? (_) {},
    );

    test('Passes attachment content to inference without expanding the displayed question', () async {
      const attachment = TextAttachment(
        name: 'source.txt',
        text: 'File content',
        sizeBytes: 12,
      );
      await service.send(
        conversationId: conversationId,
        text: 'Question',
        history: [],
        model: model,
        attachment: attachment,
        onUpdate: (_) {},
      );
      expect(llm.history!.single.text, 'Question');
      expect(llm.history!.single.attachment!.text, 'File content');
    });

    test(
      'Stores the trimmed user message and assembled assistant reply',
      () async {
        await send();

        final messages = await repository.getMessages(conversationId);
        expect(messages.map((m) => m.text), ['Question', 'First and second']);
        expect(messages.map((m) => m.role), [
          ChatRole.user,
          ChatRole.assistant,
        ]);
      },
    );

    test(
      'Rejects another conversation history before saving a message',
      () async {
        await expectLater(
          service.send(
            conversationId: conversationId,
            text: 'Question',
            history: [
              ChatMessage(
                id: 'foreign',
                conversationId: conversationId + 1,
                authorId: ChatAuthors.user,
                text: 'Private foreign text',
                createdAt: DateTime(2026),
              ),
            ],
            model: model,
            onUpdate: (_) {},
          ),
          throwsArgumentError,
        );
        expect(await repository.getMessages(conversationId), isEmpty);
        expect(llm.history, isNull);
      },
    );

    test('Passes the submitted question to the model', () async {
      await send();

      expect(llm.history!.single.text, 'Question');
    });

    test('Clears the submitted draft when the user message is saved', () async {
      await service.saveDraft(conversationId, 'Question');
      String? draftAfterSave;

      await service.send(
        conversationId: conversationId,
        text: 'Question',
        history: [],
        model: model,
        onUpdate: (update) async {
          if (update is ChatMessageSaved &&
              update.message.role == ChatRole.user) {
            draftAfterSave = (await repository.getConversations()).single.draft;
          }
        },
      );

      expect(draftAfterSave, '');
    });

    test('Preserves a new draft typed during the reply', () async {
      await service.saveDraft(conversationId, 'Question');
      await service.send(
        conversationId: conversationId,
        text: 'Question',
        history: [],
        model: model,
        onUpdate: (update) async {
          if (update is ChatMessageSaved &&
              update.message.role == ChatRole.user) {
            await service.saveDraft(conversationId, 'Next question');
          }
        },
      );

      expect(
        (await repository.getConversations()).single.draft,
        'Next question',
      );
    });

    test('Publishes the accumulated streamed reply', () async {
      final updates = <ChatUpdate>[];

      await send(onUpdate: updates.add);

      expect(
        updates.whereType<ChatMessageUpdated>().last.text,
        'First and second',
      );
    });

    test('Reports user message storage failures', () async {
      repository.failSend = true;

      await expectLater(send(), throwsA(isA<UserMessageSaveFailure>()));
    });

    test('Allows another send after a storage failure', () async {
      repository.failSend = true;
      await expectLater(send(), throwsA(isA<UserMessageSaveFailure>()));
      repository.failSend = false;

      await send();

      expect(
        (await repository.getMessages(conversationId)).first.text,
        'Question',
      );
    });

    test('Truncates conversation titles at grapheme boundaries', () async {
      final text = List.filled(41, '👨‍👩‍👧‍👦').join();

      await service.send(
        conversationId: conversationId,
        text: text,
        history: [],
        model: model,
        onUpdate: (_) {},
      );

      expect(
        (await repository.getConversations()).single.title,
        List.filled(40, '👨‍👩‍👧‍👦').join(),
      );
      expect((await repository.getMessages(conversationId)).first.text, text);
    });
  });
}

class _ChatRepository implements ChatRepository {
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
    TextAttachment? attachment,
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
      attachment: attachment,
      createdAt: DateTime.now().toUtc(),
    );
    _messages.add(message);
    _conversations[conversationId] = conversation.copyWith(
      title: conversationTitle,
      draft: clearDraft ? '' : conversation.draft,
      clearDraftAttachment: clearDraft,
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
      attachment: old.attachment,
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
  Future<void> saveDraftAttachment(
    int conversationId,
    TextAttachment? attachment,
  ) async {
    _conversations[conversationId] = _conversations[conversationId]!.copyWith(
      draftAttachment: attachment,
      clearDraftAttachment: attachment == null,
    );
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
