import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_probe_repository.dart';

class LocalModelProbeRepository implements ModelProbeRepository {
  LocalModelProbeRepository(this._files);

  final ModelFileDataSource _files;
  bool _running = false;

  @override
  Future<String> run(ModelFile model, void Function(ModelProbeStage) onStage) async {
    if (_running) throw StateError('Próba już trwa.');
    _running = true;
    LlamaEngine? engine;
    try {
      final file = await _files.file(model);
      if (!await file.exists() || await file.length() != model.sizeBytes) {
        throw StateError('Najpierw pobierz model Bielik 1.5B.');
      }
      onStage(ModelProbeStage.loading);
      engine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(file.path)),
        params: const ModelParams(
          contextSize: 512,
          device: ComputeDevice.cpu,
          gpuLayers: 0,
          numberOfThreads: 4,
          batchSize: 128,
        ),
      );
      onStage(ModelProbeStage.generating);
      final text = (await engine.create(
        const [
          LlamaChatMessage.fromText(
            role: LlamaChatRole.user,
            text: 'Odpowiedz jednym krótkim zdaniem po polsku: czym jest sztuczna inteligencja?',
          ),
        ],
        params: const GenerationParams(maxTokens: 64),
      ).text()).trim();
      if (text.isEmpty) throw StateError('Model nie zwrócił odpowiedzi.');
      return text;
    } finally {
      try {
        if (engine != null) {
          onStage(ModelProbeStage.releasing);
          await engine.dispose();
        }
      } finally {
        _running = false;
      }
    }
  }
}
