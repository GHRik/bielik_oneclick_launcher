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
  test(
    'CPU never constructs GPU; GPU errors do not retry or alter CPU',
    () async {
      final cpu = _Repository();
      final gpu = _Repository()..fail = true;
      var gpuCreations = 0;
      final router = ComputeRoutingLlmRepository(
        cpu: cpu,
        createGpu: () {
          gpuCreations++;
          return gpu;
        },
      );
      await router.generate(model, [], onStage: (_) {}).drain<void>();
      expect(gpuCreations, 0);
      await expectLater(
        router
            .generate(
              model,
              [],
              onStage: (_) {},
              computeMode: LlmComputeMode.gpu,
            )
            .drain<void>(),
        throwsA(isA<GpuAccelerationFailure>()),
      );
      expect(cpu.calls, 1);
      expect(gpu.calls, 1);
      expect(gpu.unloads, 1);
      await router
          .generate(model, [], onStage: (_) {}, computeMode: LlmComputeMode.cpu)
          .drain<void>();
      expect(cpu.calls, 2);
      expect(gpuCreations, 1);
      await router.unload();
    },
  );

  test('GPU selection is explicit; CPU parameters remain identical', () async {
    const cpu = CpuRuntimeAdapter();
    final before = cpu.parameters(defaultLlmConfiguration);
    for (final backend in GpuInferenceBackend.values) {
      final gpu = GpuInferenceAdapter(
        GpuConfiguration(enabled: true, backend: backend, layers: 16),
      );
      final parameters = gpu.parameters(defaultLlmConfiguration);
      expect(parameters.device, ComputeDevice.gpu);
      expect(
        parameters.preferredBackend,
        backend == GpuInferenceBackend.vulkan
            ? GpuBackend.vulkan
            : GpuBackend.opencl,
      );
      expect(parameters.gpuLayers, 16);
      expect(parameters.microBatchSize, 1);
      final runtime = await gpu.inspect(_Engine(backend.name, 16));
      expect(runtime.mode, LlmComputeMode.gpu);
      await expectLater(
        gpu.inspect(_Engine('CPU', 0)),
        throwsA(isA<GpuAccelerationFailure>()),
      );
    }
    final after = cpu.parameters(defaultLlmConfiguration);
    expect(after.device, before.device);
    expect(after.preferredBackend, GpuBackend.cpu);
    expect(after.gpuLayers, 0);
    expect(after.microBatchSize, before.microBatchSize);
    expect(after.flashAttention, before.flashAttention);
    expect(after.numberOfThreads, before.numberOfThreads);
  });
}
