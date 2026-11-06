import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/llm_runtime_adapter.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';

class GpuInferenceAdapter implements LlmRuntimeAdapter {
  const GpuInferenceAdapter(this.configuration);
  final GpuConfiguration configuration;

  @override
  ModelParams parameters(LlmConfiguration profile) {
    if (configuration.layers <= 0 ||
        configuration.microBatchSize <= 0 ||
        configuration.microBatchSize > profile.batchSize) {
      throw const GpuAccelerationFailure(
        'Nieprawidłowa konfiguracja warstw lub mikropartii GPU.',
      );
    }
    return ModelParams(
      contextSize: profile.contextSize,
      device: ComputeDevice.gpu,
      preferredBackend: configuration.backend == GpuInferenceBackend.vulkan
          ? GpuBackend.vulkan
          : GpuBackend.opencl,
      gpuLayers: configuration.layers,
      numberOfThreads: profile.numberOfThreads,
      batchSize: profile.batchSize,
      microBatchSize: configuration.microBatchSize,
      flashAttention: configuration.flashAttention
          ? FlashAttention.enabled
          : FlashAttention.disabled,
    );
  }

  @override
  Future<LlmRuntimeInfo> inspect(LlamaEngine engine) async {
    final backend = await engine.getBackendName();
    final layers = await engine.getResolvedGpuLayers();
    final expected = configuration.backend.name;
    if (layers == null ||
        layers <= 0 ||
        !backend.toLowerCase().contains(expected)) {
      throw GpuAccelerationFailure(
        'Silnik nie potwierdził backendu $expected i warstw GPU.',
      );
    }
    return LlmRuntimeInfo(
      mode: LlmComputeMode.gpu,
      backend: backend,
      gpuLayers: layers,
    );
  }
}
