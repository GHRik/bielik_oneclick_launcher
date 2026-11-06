import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

class GpuSettingsDraft {
  GpuSettingsDraft(GpuConfiguration configuration)
    : enabled = configuration.enabled,
      backend = configuration.backend,
      flashAttention = configuration.flashAttention,
      layers = TextEditingController(text: '${configuration.layers}'),
      microBatch = TextEditingController(
        text: '${configuration.microBatchSize}',
      );

  bool enabled;
  GpuInferenceBackend backend;
  bool flashAttention;
  final TextEditingController layers;
  final TextEditingController microBatch;

  GpuConfiguration configuration(int batchSize) {
    if (!enabled) return const GpuConfiguration();
    final layerCount = int.tryParse(layers.text.trim());
    final batch = int.tryParse(microBatch.text.trim());
    if (layerCount == null ||
        layerCount < 1 ||
        layerCount > 999 ||
        batch == null ||
        batch < 1 ||
        batch > batchSize) {
      throw const FormatException(
        'GPU: warstwy od 1 do 999, mikropartia od 1 do rozmiaru partii.',
      );
    }
    return GpuConfiguration(
      enabled: true,
      backend: backend,
      layers: layerCount,
      microBatchSize: batch,
      flashAttention: flashAttention,
    );
  }

  void reset() {
    enabled = false;
    backend = GpuInferenceBackend.vulkan;
    flashAttention = false;
    layers.text = '16';
    microBatch.text = '1';
  }

  void dispose() {
    layers.dispose();
    microBatch.dispose();
  }
}
