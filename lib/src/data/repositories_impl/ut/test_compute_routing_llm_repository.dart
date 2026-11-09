import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/compute_routing_llm_repository.dart';

class _Repository implements LlmRepository {
  bool fail = false;
  bool rejectContext = false;
  int calls = 0;
  int unloads = 0;
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
    Future<void> Function()? onPromptAccepted,
  }) async* {
    calls++;
    if (fail) throw StateError('GPU failed');
    if (rejectContext) throw ChatContextTooLong();
    onContext?.call(const ContextUsage(promptTokens: 64, contextSize: 2048));
    await onPromptAccepted?.call();
    yield 'odpowiedź';
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {
    unloads++;
  }
}

void main() {
  const model = ModelFile(name: 'test.gguf', url: '', sizeBytes: 1, sha256: '');
  group('ComputeRoutingLlmRepository', () {
    late _Repository cpu;
    late _Repository gpu;
    late ComputeRoutingLlmRepository router;
    var gpuCreations = 0;

    setUp(() {
      cpu = _Repository();
      gpu = _Repository();
      gpuCreations = 0;
      router = ComputeRoutingLlmRepository(
        cpu: cpu,
        createGpu: () {
          gpuCreations++;
          return gpu;
        },
      );
    });
    tearDown(() => router.unload());

    Future<void> generate(LlmComputeMode mode) => router
        .generate(model, [], onStage: (_) {}, computeMode: mode)
        .drain<void>();

    for (final mode in LlmComputeMode.values) {
      test(
        'Forwards prompt acceptance from the ${mode.name} runtime',
        () async {
          var accepted = false;
          await router
              .generate(
                model,
                [],
                onStage: (_) {},
                computeMode: mode,
                onPromptAccepted: () async => accepted = true,
              )
              .drain<void>();

          expect(accepted, isTrue);
        },
      );

      test('Forwards measured context from the ${mode.name} runtime', () async {
        ContextUsage? measured;
        await router
            .generate(
              model,
              [],
              onStage: (_) {},
              computeMode: mode,
              onContext: (value) => measured = value,
            )
            .drain<void>();
        expect(measured?.promptTokens, 64);
      });
    }

    test(
      'GPU context rejection is not reported as an acceleration failure',
      () async {
        gpu.rejectContext = true;

        await expectLater(
          generate(LlmComputeMode.gpu),
          throwsA(isA<ChatContextTooLong>()),
        );
      },
    );

    test('CPU inference does not construct a GPU repository', () async {
      await generate(LlmComputeMode.cpu);

      expect(cpu.calls, 1);
      expect(gpuCreations, 0);
    });

    test('GPU failure is surfaced without retrying on CPU', () async {
      gpu.fail = true;

      await expectLater(
        generate(LlmComputeMode.gpu),
        throwsA(isA<GpuAccelerationFailure>()),
      );

      expect(gpu.calls, 1);
      expect(cpu.calls, 0);
    });

    test('GPU failure unloads the failed runtime', () async {
      gpu.fail = true;

      await expectLater(
        generate(LlmComputeMode.gpu),
        throwsA(isA<GpuAccelerationFailure>()),
      );

      expect(gpu.unloads, 1);
    });

    test('CPU remains usable after GPU inference fails', () async {
      await generate(LlmComputeMode.cpu);
      gpu.fail = true;
      await expectLater(
        generate(LlmComputeMode.gpu),
        throwsA(isA<GpuAccelerationFailure>()),
      );

      await generate(LlmComputeMode.cpu);

      expect(cpu.calls, 2);
      expect(gpuCreations, 1);
    });
  });
}
