import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/gpu_inference_adapter.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/llm_runtime_adapter.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/compute_routing_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

class _Engine extends Fake implements LlamaEngine {
  _Engine(this.name, this.layers);
  final String name;
  final int? layers;
  @override
  Future<String> getBackendName() async => name;
  @override
  Future<int?> getResolvedGpuLayers() async => layers;
}

class _Repository implements LlmRepository {
  bool fail = false;
  int calls = 0;
  int unloads = 0;
  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
  }) async* {
    calls++;
    if (fail) throw StateError('GPU failed');
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
  group('CPU and GPU routing isolation', () {
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

  group('Runtime parameter adapters', () {
    for (final backend in GpuInferenceBackend.values) {
      GpuInferenceAdapter adapter() => GpuInferenceAdapter(
        GpuConfiguration(enabled: true, backend: backend, layers: 16),
      );

      test('${backend.name} uses explicit GPU parameters', () {
        final parameters = adapter().parameters(defaultLlmConfiguration);

        expect(parameters.device, ComputeDevice.gpu);
        expect(
          parameters.preferredBackend,
          backend == GpuInferenceBackend.vulkan
              ? GpuBackend.vulkan
              : GpuBackend.opencl,
        );
        expect(parameters.gpuLayers, 16);
        expect(parameters.microBatchSize, 1);
      });

      test('${backend.name} recognizes an active GPU runtime', () async {
        final runtime = await adapter().inspect(_Engine(backend.name, 16));

        expect(runtime.mode, LlmComputeMode.gpu);
      });

      test('${backend.name} rejects silent CPU fallback', () async {
        await expectLater(
          adapter().inspect(_Engine('CPU', 0)),
          throwsA(isA<GpuAccelerationFailure>()),
        );
      });

      test('${backend.name} configuration does not mutate CPU parameters', () {
        const cpu = CpuRuntimeAdapter();
        final before = cpu.parameters(defaultLlmConfiguration);

        adapter().parameters(defaultLlmConfiguration);
        final after = cpu.parameters(defaultLlmConfiguration);

        expect(after.device, before.device);
        expect(after.preferredBackend, GpuBackend.cpu);
        expect(after.gpuLayers, 0);
        expect(after.microBatchSize, before.microBatchSize);
        expect(after.flashAttention, before.flashAttention);
        expect(after.numberOfThreads, before.numberOfThreads);
      });
    }
  });
}
