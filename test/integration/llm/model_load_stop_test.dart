import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class _Engine extends Fake implements LlamaEngine {
  int generations = 0;
  int disposals = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #chatTemplate:
        return Future.value(
          const LlamaChatTemplateResult(prompt: '', tokenCount: 1),
        );
      case #getBackendName:
        return Future.value('CPU');
      case #create:
        generations++;
        return const Stream<LlamaCompletionChunk>.empty();
      case #cancelGeneration:
        return null;
      case #dispose:
        disposals++;
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('Stopping while the model loads', () {
    late LocalLlmRepository repository;
    late List<Completer<LlamaEngine>> loads;
    late _Engine engine;
    var configuration = defaultLlmConfiguration;
    const model = ModelFile(
      name: 'test.gguf',
      url: '',
      sizeBytes: 1,
      sha256: '',
    );
    final question = [
      ChatMessage(
        id: '1',
        conversationId: 1,
        authorId: ChatAuthors.user,
        text: 'Cześć',
        createdAt: DateTime.utc(2026),
      ),
    ];

    setUp(() async {
      final directory = await Directory.systemTemp.createTemp('load-stop-test');
      addTearDown(() => directory.delete(recursive: true));
      final folder = await Directory('${directory.path}/models').create();
      await File('${folder.path}/test.gguf').writeAsBytes([1]);
      loads = [];
      engine = _Engine();
      configuration = defaultLlmConfiguration;
      repository = LocalLlmRepository(
        ModelFileDataSource(directory: () async => directory),
        configurationFor: (_) => configuration,
        loadEngine: (_, _) {
          loads.add(Completer<LlamaEngine>());
          return loads.last.future;
        },
      );
    });

    /// Starts a request and returns once the engine load has been requested
    /// [expectedLoads] times.
    Future<({Future<void> done, List<LlmStage> stages})> request({
      required int expectedLoads,
    }) async {
      final stages = <LlmStage>[];
      final done = repository
          .generate(model, question, onStage: stages.add)
          .drain<void>();
      while (loads.length < expectedLoads ||
          !stages.contains(LlmStage.loading)) {
        await Future<void>.delayed(Duration.zero);
      }
      return (done: done, stages: stages);
    }

    const prompt = Duration(seconds: 2);

    test('Ends the request at once, before the load finishes', () async {
      final first = await request(expectedLoads: 1);
      repository.stop();

      await first.done.timeout(prompt);
      expect(loads.single.isCompleted, isFalse);
      expect(engine.generations, 0);
      loads.single.complete(engine);
    });

    test('The next request continues with the load left running', () async {
      final first = await request(expectedLoads: 1);
      repository.stop();
      await first.done.timeout(prompt);

      final second = await request(expectedLoads: 1);
      loads.single.complete(engine);
      await second.done.timeout(prompt);

      expect(loads, hasLength(1));
      expect(engine.generations, 1);
    });

    test('A model loaded after the stop serves the next request', () async {
      final first = await request(expectedLoads: 1);
      repository.stop();
      await first.done.timeout(prompt);
      loads.single.complete(engine);
      await Future<void>.delayed(Duration.zero);

      await repository
          .generate(model, question, onStage: (_) {})
          .drain<void>()
          .timeout(prompt);

      expect(loads, hasLength(1));
      expect(engine.generations, 1);
    });

    test('The next request can be stopped during the same load', () async {
      final first = await request(expectedLoads: 1);
      repository.stop();
      await first.done.timeout(prompt);
      final second = await request(expectedLoads: 1);
      repository.stop();

      await second.done.timeout(prompt);
      expect(loads.single.isCompleted, isFalse);
      expect(engine.generations, 0);
      loads.single.complete(engine);
    });

    test(
      'Unloading waits for the running load and releases its engine',
      () async {
        final first = await request(expectedLoads: 1);
        repository.stop();
        await first.done.timeout(prompt);

        var unloaded = false;
        final unload = repository.unload().then((_) => unloaded = true);
        await Future<void>.delayed(Duration.zero);
        expect(unloaded, isFalse);

        loads.single.complete(engine);
        await unload.timeout(prompt);
        expect(engine.disposals, 1);
      },
    );

    test(
      'A load that fails after the stop is retried by the next request',
      () async {
        final first = await request(expectedLoads: 1);
        repository.stop();
        await first.done.timeout(prompt);
        loads.single.completeError(StateError('out of memory'));
        await Future<void>.delayed(Duration.zero);

        final second = await request(expectedLoads: 2);
        loads.last.complete(engine);
        await second.done.timeout(prompt);

        expect(engine.generations, 1);
      },
    );

    test(
      'Changed settings replace the engine left by a stopped load',
      () async {
        final first = await request(expectedLoads: 1);
        repository.stop();
        await first.done.timeout(prompt);
        configuration = defaultLlmConfiguration.copyWith(contextSize: 4096);

        final replaced = _Engine();
        final second = repository
            .generate(model, question, onStage: (_) {})
            .drain<void>();
        loads.first.complete(engine);
        while (loads.length < 2) {
          await Future<void>.delayed(Duration.zero);
        }
        loads.last.complete(replaced);
        await second.timeout(prompt);

        expect(engine.disposals, 1);
        expect(engine.generations, 0);
        expect(replaced.generations, 1);
      },
    );

    test(
      'A load failure still reaches the request that waits for it',
      () async {
        final first = await request(expectedLoads: 1);
        loads.single.completeError(StateError('cannot load'));

        await expectLater(first.done, throwsStateError);
      },
    );
  });
}
