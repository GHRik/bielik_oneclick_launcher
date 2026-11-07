import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/configuration/system_prompt.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

class _Engine extends Fake implements LlamaEngine {
  final counted = <List<LlamaChatMessage>>[];
  final generated = <List<LlamaChatMessage>>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final messages = invocation.positionalArguments.isEmpty
        ? <LlamaChatMessage>[]
        : invocation.positionalArguments.first as List<LlamaChatMessage>;
    switch (invocation.memberName) {
      case #chatTemplate:
        counted.add(messages);
        return Future.value(
          LlamaChatTemplateResult(
            prompt: '',
            tokenCount: messages.fold<int>(
              0,
              (sum, m) => sum + m.content.length,
            ),
          ),
        );
      case #getBackendName:
        return Future.value('CPU');
      case #create:
        generated.add(messages);
        return const Stream<LlamaCompletionChunk>.empty();
      case #dispose:
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('Bielik system prompt', () {
    late _Engine engine;
    late LocalLlmRepository repository;
    var configuration = defaultLlmConfiguration;
    const model = ModelFile(
      name: 'test.gguf',
      url: '',
      sizeBytes: 1,
      sha256: '',
    );

    setUp(() async {
      final directory = await Directory.systemTemp.createTemp('prompt-test');
      addTearDown(() => directory.delete(recursive: true));
      final folder = await Directory('${directory.path}/models').create();
      await File('${folder.path}/test.gguf').writeAsBytes([1]);
      engine = _Engine();
      configuration = defaultLlmConfiguration.copyWith(
        contextSize: 512,
        responseTokens: 64,
      );
      repository = LocalLlmRepository(
        ModelFileDataSource(directory: () async => directory),
        systemPrompt: bielikSystemPrompt,
        configurationFor: (_) => configuration,
        loadEngine: (_, _) async => engine,
      );

      addTearDown(repository.unload);
    });

    ChatMessage message(String id, String text, String author) => ChatMessage(
      id: id,
      conversationId: 1,
      authorId: author,
      text: text,
      createdAt: DateTime.utc(2026),
    );

    Future<void> generateTrimmedHistory() => repository.generate(model, [
      message('1', 'a' * 300, ChatAuthors.user),
      message('2', 'b' * 200, ChatAuthors.assistant),
      message('3', 'Cześć', ChatAuthors.user),
    ], onStage: (_) {}).drain<void>();

    test(
      'Includes exactly one system prompt in every token counting request',
      () async {
        await generateTrimmedHistory();

        expect(engine.counted.length, greaterThan(1));
        for (final messages in engine.counted) {
          expect(messages.first.role, LlamaChatRole.system);
          expect(messages.first.content, bielikSystemPrompt);
          expect(
            messages.where((m) => m.role == LlamaChatRole.system),
            hasLength(1),
          );
        }
      },
    );

    test('Preserves the system prompt when old turns are trimmed', () async {
      await generateTrimmedHistory();

      final messages = engine.generated.single;
      expect(messages, hasLength(2));
      expect(messages.first.role, LlamaChatRole.system);
      expect(messages.first.content, bielikSystemPrompt);
      expect(messages.last.content, 'Cześć');
    });

    test(
      'Rejects inference when the system prompt exceeds the budget',
      () async {
        configuration = defaultLlmConfiguration.copyWith(
          contextSize: 128,
          responseTokens: 64,
          safetyTokens: 32,
        );

        await expectLater(
          repository.generate(model, [
            message('4', 'Question', ChatAuthors.user),
          ], onStage: (_) {}).drain<void>(),
          throwsA(isA<ChatContextTooLong>()),
        );

        expect(engine.generated, isEmpty);
      },
    );
  });
}
