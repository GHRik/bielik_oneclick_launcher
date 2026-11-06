import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class _CpuEngine extends Fake implements LlamaEngine {
  int disposals = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #chatTemplate:
        return Future.value(
          const LlamaChatTemplateResult(prompt: '', tokenCount: 0),
        );
      case #getBackendName:
        return Future.value('CPU');
      case #create:
        return const Stream<LlamaCompletionChunk>.empty();
      case #dispose:
        disposals++;
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  test('Inference forces CPU even for a legacy GPU request', () async {
    final directory = await Directory.systemTemp.createTemp('bielik-cpu-test');
    addTearDown(() => directory.delete(recursive: true));
    final models = await Directory('${directory.path}/models').create();
    await File('${models.path}/test.gguf').writeAsBytes([1]);
    const model = ModelFile(
      name: 'test.gguf',
      url: '',
      sizeBytes: 1,
      sha256: '',
    );
    final params = <ModelParams>[];
    final engine = _CpuEngine();
    final repository = LocalLlmRepository(
      ModelFileDataSource(directory: () async => directory),
      configurationFor: (_) => defaultLlmConfiguration,
      loadEngine: (_, settings) async {
        params.add(settings);
        return engine;
      },
    );
    for (final mode in [null, LlmComputeMode.gpu, LlmComputeMode.cpu]) {
      LlmRuntimeInfo? runtime;
      await repository
          .generate(
            model,
            [],
            onStage: (_) {},
            computeMode: mode,
            onLoaded: (value) => runtime = value,
          )
          .drain<void>();
      expect(runtime!.mode, LlmComputeMode.cpu);
      expect(runtime!.gpuLayers, 0);
    }
    expect(params, hasLength(1));
    expect(params.single.device, ComputeDevice.cpu);
    expect(params.single.preferredBackend, GpuBackend.cpu);
    expect(params.single.gpuLayers, 0);
    expect(
      params.single.numberOfThreads,
      defaultLlmConfiguration.numberOfThreads,
    );
    await repository.unload();
    expect(engine.disposals, 1);
  });
}
