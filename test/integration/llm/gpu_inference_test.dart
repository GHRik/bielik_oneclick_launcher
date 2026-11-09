import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class _CpuEngine extends Fake implements LlamaEngine {
  int disposals = 0;
  int tokenCount = 12;
  final requests = <GenerationParams>[];
  final prompts = <List<LlamaChatMessage>>[];
  List<LlamaCompletionChunk> chunks = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #chatTemplate:
        return Future.value(
          LlamaChatTemplateResult(prompt: '', tokenCount: tokenCount),
        );
      case #getBackendName:
        return Future.value('CPU');
      case #create:
        requests.add(invocation.namedArguments[#params] as GenerationParams);
        prompts.add(
          List<LlamaChatMessage>.of(
            invocation.positionalArguments.first as List<LlamaChatMessage>,
          ),
        );
        return Stream<LlamaCompletionChunk>.fromIterable(chunks);
      case #dispose:
        disposals++;
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('CPU runtime isolation', () {
    late LocalLlmRepository repository;
    late _CpuEngine engine;
    late List<ModelParams> params;
    const model = ModelFile(
      name: 'test.gguf',
      url: '',
      sizeBytes: 1,
      sha256: '',
    );

    setUp(() async {
      final directory = await Directory.systemTemp.createTemp(
        'bielik-cpu-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final models = await Directory('${directory.path}/models').create();
      await File('${models.path}/test.gguf').writeAsBytes([1]);
      params = <ModelParams>[];
      engine = _CpuEngine();
      repository = LocalLlmRepository(
        ModelFileDataSource(directory: () async => directory),
        configurationFor: (_) => defaultLlmConfiguration,
        loadEngine: (_, settings) async {
          params.add(settings);
          return engine;
        },
      );

      addTearDown(repository.unload);
    });

    for (final mode in [null, LlmComputeMode.gpu, LlmComputeMode.cpu]) {
      test(
        'Reports CPU execution for a ${mode?.name ?? 'default'} request',
        () async {
          LlmRuntimeInfo? runtime;

          await repository
              .generate(
                model,
                [],
                onStage: (_) {},
                computeMode: mode,
                onLoaded: (value) => runtime = value,
              )
              .drain<void>();

          expect(runtime!.mode, LlmComputeMode.cpu);
          expect(runtime!.gpuLayers, 0);
        },
      );
    }

    test('Loads the engine with CPU-only parameters', () async {
      await repository.generate(model, [], onStage: (_) {}).drain<void>();

      expect(params.single.device, ComputeDevice.cpu);
      expect(params.single.preferredBackend, GpuBackend.cpu);
      expect(params.single.gpuLayers, 0);
      expect(
        params.single.numberOfThreads,
        defaultLlmConfiguration.numberOfThreads,
      );
    });

    test('Reuses the CPU engine across legacy compute requests', () async {
      for (final mode in [null, LlmComputeMode.gpu, LlmComputeMode.cpu]) {
        await repository
            .generate(model, [], onStage: (_) {}, computeMode: mode)
            .drain<void>();
      }

      expect(params, hasLength(1));
    });

    ChatMessage message(int conversationId, String text) => ChatMessage(
      id: '$conversationId-$text',
      conversationId: conversationId,
      authorId: ChatAuthors.user,
      text: text,
      createdAt: DateTime(2026),
    );

    test(
      'A different conversation starts without the previous prompt cache',
      () async {
        for (final id in [1, 1, 2, 1]) {
          await repository.generate(model, [
            message(id, 'Question'),
          ], onStage: (_) {}).drain<void>();
        }
        expect(engine.requests.map((request) => request.reusePromptPrefix), [
          false,
          true,
          false,
          false,
        ]);
        expect(params, hasLength(1));
      },
    );

    test(
      'A new conversation sends only its own messages to the engine',
      () async {
        await repository.generate(model, [
          message(1, 'Private old text'),
        ], onStage: (_) {}).drain<void>();
        await repository.generate(model, [
          message(2, 'New question'),
        ], onStage: (_) {}).drain<void>();
        expect(engine.prompts.last.map((message) => message.content), [
          'New question',
        ]);
        expect(engine.requests.last.reusePromptPrefix, isFalse);
      },
    );

    test(
      'Mixed conversation histories are rejected before loading the model',
      () async {
        await expectLater(
          repository.generate(model, [
            message(1, 'Old'),
            message(2, 'New'),
          ], onStage: (_) {}).drain<void>(),
          throwsArgumentError,
        );
        expect(params, isEmpty);
      },
    );

    test(
      'Reports tokenizer counts before generation and final backend usage',
      () async {
        engine.chunks = [
          LlamaCompletionChunk(
            id: 'reply',
            object: 'chat.completion.chunk',
            created: 0,
            model: 'test',
            choices: [],
            usage: const LlamaGenerationUsage(
              promptTokens: 12,
              completionTokens: 7,
            ),
          ),
        ];
        final measurements = <ContextUsage>[];
        await repository
            .generate(
              model,
              [message(1, 'Question')],
              onStage: (_) {},
              onContext: measurements.add,
            )
            .drain<void>();
        expect(measurements.map((value) => value.usedTokens), [12, 19]);
        expect(
          measurements.last.contextSize,
          defaultLlmConfiguration.contextSize,
        );
      },
    );

    test('Unloading disposes the CPU engine', () async {
      await repository.generate(model, [], onStage: (_) {}).drain<void>();

      await repository.unload();

      expect(engine.disposals, 1);
    });
  });
}
