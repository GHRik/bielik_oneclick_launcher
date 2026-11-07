import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/llm_runtime_adapter.dart';

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
  group('CpuRuntimeAdapter', () {
    const adapter = CpuRuntimeAdapter();

    test(
      'parameters force CPU while preserving the configured model profile',
      () {
        final parameters = adapter.parameters(defaultLlmConfiguration);

        expect(parameters.device, ComputeDevice.cpu);
        expect(parameters.preferredBackend, GpuBackend.cpu);
        expect(parameters.gpuLayers, 0);
        expect(parameters.contextSize, defaultLlmConfiguration.contextSize);
        expect(
          parameters.numberOfThreads,
          defaultLlmConfiguration.numberOfThreads,
        );
        expect(parameters.batchSize, defaultLlmConfiguration.batchSize);
      },
    );

    test(
      'inspect reports CPU mode with the backend supplied by the engine',
      () async {
        final runtime = await adapter.inspect(_Engine('CPU', 0));

        expect(runtime.mode, LlmComputeMode.cpu);
        expect(runtime.backend, 'CPU');
        expect(runtime.gpuLayers, 0);
      },
    );
  });
}
