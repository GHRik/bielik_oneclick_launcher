import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_service.dart';

import 'support/in_memory_chat_repository.dart';

class _Llm implements LlmRepository {
  List<ChatMessage>? history;
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
  }) {
    this.history = history;
    return Stream.fromIterable(['Pierwszy', ' i drugi']);
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {}
}

void main() {
  test('Pure service persists both roles and preserves a draft typed during the reply', () async {
    final repository = InMemoryChatRepository();
    final conversation = await repository.createConversation();
    final llm = _Llm();
    final service = ChatService(repository, llmRepository: llm);
    final updates = <ChatUpdate>[];
    await service.saveDraft(conversation.id, 'Pytanie');
    await service.send(
      conversationId: conversation.id,
      text: '  Pytanie  ',
      history: [],
      model: const ModelFile(
        name: 'test.gguf',
        url: 'https://example.com',
        sizeBytes: 1,
        sha256: '',
      ),
      onUpdate: (update) async {
        updates.add(update);
        if (update is ChatMessageSaved &&
            update.message.role == ChatRole.user) {
          expect((await repository.getConversations()).single.draft, '');
          await service.saveDraft(conversation.id, 'Następne pytanie');
        }
      },
    );
    final messages = await repository.getMessages(conversation.id);
    expect(messages.map((m) => m.text), ['Pytanie', 'Pierwszy i drugi']);
    expect(messages.map((m) => m.role), [ChatRole.user, ChatRole.assistant]);
    expect(llm.history!.single.text, 'Pytanie');
    expect(
      (await repository.getConversations()).single.draft,
      'Następne pytanie',
    );
    expect(
      updates.whereType<ChatMessageUpdated>().last.text,
      'Pierwszy i drugi',
    );
  });

  test('Title preserves grapheme boundaries and failed storage does not poison the queue', () async {
    final repository = InMemoryChatRepository();
    final conversation = await repository.createConversation();
    final service = ChatService(repository);
    repository.failSend = true;
    await expectLater(
      service.send(
        conversationId: conversation.id,
        text: 'Pytanie',
        history: [],
        onUpdate: (_) {},
      ),
      throwsA(isA<UserMessageSaveFailure>()),
    );
    repository.failSend = false;
    final text = List.filled(41, '👨‍👩‍👧‍👦').join();
    await service.send(
      conversationId: conversation.id,
      text: text,
      history: [],
      onUpdate: (_) {},
    );
    expect(
      (await repository.getConversations()).single.title,
      List.filled(40, '👨‍👩‍👧‍👦').join(),
    );
    expect((await repository.getMessages(conversation.id)).single.text, text);
  });
}
