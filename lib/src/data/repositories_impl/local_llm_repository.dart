import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';

class LocalLlmRepository implements LlmRepository {
  LocalLlmRepository(
    this._files, {
    required this.configurationFor,
    this.metrics,
  });

  final ModelFileDataSource _files;
  final GenerationMetrics? metrics;
  final LlmConfiguration Function(ModelFile) configurationFor;
  LlmConfiguration? _loadedConfiguration;
  LlamaEngine? _engine;
  String? _loadedPath;
  bool _active = false;
  bool _stopped = false;

  List<LlamaChatMessage> _engineMessages(List<ContextMessage> messages) =>
      messages
          .map(
            (message) => LlamaChatMessage.fromText(
              role: message.role == ChatRole.user
                  ? LlamaChatRole.user
                  : LlamaChatRole.assistant,
              text: message.text,
            ),
          )
          .toList();

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
  }) async* {
    if (_active) throw StateError('Generowanie już trwa.');
    _active = true;
    _stopped = false;
    metrics?.begin();
    try {
      final configuration = configurationFor(model);
      final contextPolicy = ChatContextPolicy(
        contextSize: configuration.contextSize,
        responseTokens: configuration.responseTokens,
        safetyTokens: configuration.safetyTokens,
      );
      final file = await _files.file(model);
      if (!await file.exists() || await file.length() != model.sizeBytes) {
        throw StateError('Najpierw pobierz wybrany model na ekranie głównym.');
      }
      if (_loadedPath != file.path ||
          _engine == null ||
          _loadedConfiguration != configuration) {
        onStage(LlmStage.loading);
        await _engine?.dispose();
        _engine = null;
        _loadedPath = null;
        if (_stopped) return;
        _engine = await LlamaEngine.load(
          LlamaModel(ModelSource.path(file.path)),
          params: ModelParams(
            contextSize: contextPolicy.contextSize,
            device: configuration.useGpu
                ? ComputeDevice.gpu
                : ComputeDevice.cpu,
            gpuLayers: configuration.gpuLayers,
            numberOfThreads: configuration.numberOfThreads,
            batchSize: configuration.batchSize,
          ),
        );
        _loadedPath = file.path;
        _loadedConfiguration = configuration;
      }
      if (_stopped) return;
      final engine = _engine!;
      final context = await contextPolicy.prepare(
        history,
        isCancelled: () => _stopped,
        countTokens: (messages) async {
          final template = await engine.chatTemplate(_engineMessages(messages));
          return template.tokenCount ??
              await engine.getTokenCount(template.prompt);
        },
      );
      if (_stopped) return;
      onStage(LlmStage.generating);
      await for (final chunk in engine.create(
        _engineMessages(context),
        params: GenerationParams(
          maxTokens: configuration.responseTokens,
          temp: configuration.temperature,
          topK: configuration.topK,
          topP: configuration.topP,
          minP: configuration.minP,
          penalty: configuration.repeatPenalty,
          seed: configuration.seed,
        ),
      )) {
        final usage = chunk.usage;
        if (usage != null) {
          metrics?.complete(
            tokens: usage.completionTokens,
            duration: usage.duration,
          );
        }
        if (_stopped) break;
        if (chunk.text.isNotEmpty) {
          metrics?.firstText();
          yield chunk.text;
        }
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
    _loadedConfiguration = null;
    await engine?.dispose();
  }
}
