enum LlmComputeMode { cpu, gpu }

class LlmRuntimeInfo {
  const LlmRuntimeInfo({
    required this.mode,
    required this.backend,
    required this.gpuLayers,
  });

  final LlmComputeMode mode;
  final String backend;
  final int gpuLayers;
}

class GpuAccelerationFailure implements Exception {
  const GpuAccelerationFailure(this.reason);
  final String reason;
}
