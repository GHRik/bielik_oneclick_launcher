import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/gpu_inference_adapter.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';

class _Engine extends Fake implements LlamaEngine {
  _Engine(this.name, this.layers);
  final String name;
  final int? layers;
  @override
  Future<String> getBackendName() async => name;
  @override
  Future<int?> getResolvedGpuLayers() async => layers;
}

void main() {
  group('GpuInferenceAdapter', () {
    for (final backend in GpuInferenceBackend.values) {
      GpuInferenceAdapter adapter() => GpuInferenceAdapter(
        GpuConfiguration(enabled: true, backend: backend, layers: 16),
      );

      test('${backend.name} parameters select the requested GPU backend', () {
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

      test(
        '${backend.name} inspect recognizes an active GPU runtime',
        () async {
          final runtime = await adapter().inspect(_Engine(backend.name, 16));

          expect(runtime.mode, LlmComputeMode.gpu);
        },
      );

      test('${backend.name} inspect rejects silent CPU fallback', () async {
        await expectLater(
          adapter().inspect(_Engine('CPU', 0)),
          throwsA(isA<GpuAccelerationFailure>()),
        );
      });
    }
  });
}
