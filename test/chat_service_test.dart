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
    return Stream.fromIterable(['First', ' and second']);
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {}
}

void main() {
  group('Chat service message submission', () {
    late InMemoryChatRepository repository;
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
      repository = InMemoryChatRepository();
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
