import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

class LocalLlmRepository implements LlmRepository {
  LocalLlmRepository(this._files);

  final ModelFileDataSource _files;
  LlamaEngine? _engine;
  String? _loadedPath;
  bool _active = false;
  bool _stopped = false;

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
  }) async* {
    if (_active) throw StateError('Generowanie już trwa.');
    _active = true;
    _stopped = false;
    try {
      final file = await _files.file(model);
      if (!await file.exists() || await file.length() != model.sizeBytes) {
        throw StateError('Najpierw pobierz wybrany model na ekranie głównym.');
      }
      if (_loadedPath != file.path || _engine == null) {
        onStage(LlmStage.loading);
        await _engine?.dispose();
        _engine = null;
        _loadedPath = null;
        if (_stopped) return;
        _engine = await LlamaEngine.load(
          LlamaModel(ModelSource.path(file.path)),
          params: const ModelParams(
            contextSize: 2048,
            device: ComputeDevice.cpu,
            gpuLayers: 0,
            numberOfThreads: 4,
            batchSize: 128,
          ),
        );
        _loadedPath = file.path;
      }
      if (_stopped) return;
      final engine = _engine!;
      final turns = <(LlamaChatRole, String)>[];
      for (final message in history.where((message) => message.text.trim().isNotEmpty)) {
        final role = message.authorId == 'local-user'
            ? LlamaChatRole.user : LlamaChatRole.assistant;
        if (turns.isNotEmpty && turns.last.$1 == role) {
          final previous = turns.removeLast();
          turns.add((role, '${previous.$2}\n\n${message.text}'));
        } else {
          turns.add((role, message.text));
        }
      }
      final messages = turns.map((turn) =>
          LlamaChatMessage.fromText(role: turn.$1, text: turn.$2)).toList();
      while (messages.isNotEmpty) {
        final template = await engine.chatTemplate(messages);
        final count = template.tokenCount ?? await engine.getTokenCount(template.prompt);
        if (_stopped) return;
        if (count <= 1504) break;
        if (messages.length == 1) {
          throw StateError('Wiadomość jest za długa. Skróć ją i spróbuj ponownie.');
        }
        messages.removeAt(0);
        while (messages.length > 1 && messages.first.role != LlamaChatRole.user) {
          messages.removeAt(0);
        }
      }
      if (_stopped) return;
      onStage(LlmStage.generating);
      await for (final chunk in engine.create(
        messages,
        params: const GenerationParams(maxTokens: 512),
      )) {
        if (_stopped) break;
        if (chunk.text.isNotEmpty) yield chunk.text;
      }
    } finally {
      _active = false;
    }
  }

  @override
  void stop() {
    _stopped = true;
    _engine?.cancelGeneration();
  }

  @override
  Future<void> unload() async {
    if (_active) throw StateError('Najpierw zatrzymaj generowanie.');
    final engine = _engine;
    _engine = null;
    _loadedPath = null;
    await engine?.dispose();
  }
}
