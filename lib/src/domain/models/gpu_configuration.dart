enum GpuInferenceBackend { vulkan, opencl }

class GpuConfiguration {
  const GpuConfiguration({
    this.enabled = false,
    this.backend = GpuInferenceBackend.vulkan,
    this.layers = 16,
    this.microBatchSize = 1,
    this.flashAttention = false,
  }) : assert(layers > 0),
       assert(microBatchSize > 0);

  final bool enabled;
  final GpuInferenceBackend backend;
  final int layers;
  final int microBatchSize;
  final bool flashAttention;
}
