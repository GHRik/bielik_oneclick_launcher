import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/gpu_inference_adapter.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/llm_runtime_adapter.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

void main() {
  group('CPU and GPU adapter isolation', () {
    for (final backend in GpuInferenceBackend.values) {
      test('${backend.name} configuration does not mutate CPU parameters', () {
        const cpu = CpuRuntimeAdapter();
        final before = cpu.parameters(defaultLlmConfiguration);

        GpuInferenceAdapter(
          GpuConfiguration(enabled: true, backend: backend, layers: 16),
        ).parameters(defaultLlmConfiguration);
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
