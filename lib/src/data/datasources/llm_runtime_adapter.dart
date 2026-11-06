import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';

abstract interface class LlmRuntimeAdapter {
  ModelParams parameters(LlmConfiguration configuration);
  Future<LlmRuntimeInfo> inspect(LlamaEngine engine);
}

class CpuRuntimeAdapter implements LlmRuntimeAdapter {
  const CpuRuntimeAdapter();

  @override
  ModelParams parameters(LlmConfiguration configuration) => ModelParams(
    contextSize: configuration.contextSize,
    device: ComputeDevice.cpu,
    preferredBackend: GpuBackend.cpu,
    gpuLayers: 0,
    numberOfThreads: configuration.numberOfThreads,
    batchSize: configuration.batchSize,
  );

  @override
  Future<LlmRuntimeInfo> inspect(LlamaEngine engine) async => LlmRuntimeInfo(
    mode: LlmComputeMode.cpu,
    backend: await engine.getBackendName(),
    gpuLayers: 0,
  );
}
