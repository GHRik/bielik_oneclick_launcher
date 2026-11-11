import 'dart:async';

import 'package:llamadart/llamadart.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/llm_runtime_adapter.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';

typedef LlmEngineLoader = Future<LlamaEngine> Function(
  String path,
  ModelParams params,
);

class LocalLlmRepository implements LlmRepository {
  LocalLlmRepository(
    this._files, {
    required this.configurationFor,
    this.metrics,
    this.systemPrompt = '',
    this.systemPromptProvider,
    this.runtimeAdapter = const CpuRuntimeAdapter(),
    LlmEngineLoader? loadEngine,
  }) : _loadEngine = loadEngine ?? _loadNativeEngine;

  final ModelFileDataSource _files;
  final GenerationMetrics? metrics;
  final String systemPrompt;
  final String Function()? systemPromptProvider;
  String? _contextSystemPrompt;
  final LlmRuntimeAdapter runtimeAdapter;
  final LlmConfiguration Function(ModelFile) configurationFor;
  final LlmEngineLoader _loadEngine;
  LlmConfiguration? _loadedConfiguration;

  static Future<LlamaEngine> _loadNativeEngine(
    String path,
    ModelParams params,
  ) => LlamaEngine.load(LlamaModel(ModelSource.path(path)), params: params);
  LlamaEngine? _engine;
  String? _loadedPath;
  int? _contextConversationId;
  bool _active = false;
  bool _stopped = false;

  /// The engine load that is still running. A load cannot be interrupted, so
  /// a stopped request leaves it running: the next request for the same model
  /// continues with it and [unload] waits for it before releasing memory.
  Future<void>? _pendingLoad;
  Completer<void>? _stopSignal;

  Future<void> _load(String path, LlmConfiguration configuration) {
    final load = () async {
      _engine = await _loadEngine(
        path,
        runtimeAdapter.parameters(configuration),
      );
      _loadedPath = path;
      _loadedConfiguration = configuration;
    }();
    _pendingLoad = load;
    unawaited(
      load.then((_) {}, onError: (Object _) {}).whenComplete(() {
        if (identical(_pendingLoad, load)) _pendingLoad = null;
      }),
    );
    return load;
  }

  /// Waits for [load], but no longer than until [stop] is called.
  Future<void> _loadUnlessStopped(Future<void> load) async {
    if (_stopped) return;
    final signal = _stopSignal = Completer<void>();
    try {
      await Future.any([load, signal.future]);
    } finally {
      _stopSignal = null;
    }
  }

  List<LlamaChatMessage> _engineMessages(
    List<ContextMessage> messages,
    String systemPrompt,
  ) => [
    if (systemPrompt.trim().isNotEmpty)
      LlamaChatMessage.fromText(role: LlamaChatRole.system, text: systemPrompt),
    ...messages.map(
      (message) => LlamaChatMessage.fromText(
        role: message.role == ChatRole.user
            ? LlamaChatRole.user
            : LlamaChatRole.assistant,
        text: message.text,
      ),
    ),
  ];

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
    Future<void> Function()? onPromptAccepted,
  }) async* {
    if (_active) throw StateError('Generowanie już trwa.');
    final conversationId = history.isEmpty
        ? null
        : history.first.conversationId;
    if (history.any((message) => message.conversationId != conversationId)) {
      throw ArgumentError('A generation cannot combine conversations.');
    }
    _active = true;
    _stopped = false;
    metrics?.begin();
    try {
      final prompt = systemPromptProvider?.call() ?? systemPrompt;
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
      final running = _pendingLoad;
      if (running != null) {
        // Left by a stopped request. If it fails, the load below reports it.
        onStage(LlmStage.loading);
        await _loadUnlessStopped(running.then((_) {}, onError: (Object _) {}));
        if (_stopped) return;
      }
      if (_loadedPath != file.path ||
          _engine == null ||
          _loadedConfiguration != configuration) {
        onStage(LlmStage.loading);
        await _engine?.dispose();
        _engine = null;
        _loadedPath = null;
        _contextConversationId = null;
        if (_stopped) return;
        await _loadUnlessStopped(_load(file.path, configuration));
      }
      if (_stopped) return;
      final engine = _engine!;
      var promptTokens = 0;
      var omitted = <ChatMessage>[];
      onStage(LlmStage.analyzing);
      final context = await contextPolicy.prepare(
        history,
        isCancelled: () => _stopped,
        onOmittedMessages: (messages) => omitted = messages,
        countTokens: (messages) async {
          final template = await engine.chatTemplate(
            _engineMessages(messages, prompt),
          );
          promptTokens =
              template.tokenCount ??
              await engine.getTokenCount(template.prompt);
          return promptTokens;
        },
      );
      if (_stopped) return;
      final runtime = await runtimeAdapter.inspect(engine);
      if (_stopped) return;
      onLoaded?.call(runtime);
      onContext?.call(
        ContextUsage(
          promptTokens: promptTokens,
          contextSize: configuration.contextSize,
          omittedMessageIds: List.unmodifiable(omitted.map((m) => m.id)),
          omittedAttachmentNames: List.unmodifiable(
            omitted.map((m) => m.attachment?.name).whereType<String>().toSet(),
          ),
        ),
      );
      await onPromptAccepted?.call();
      if (_stopped) return;
      final reusePromptPrefix =
          conversationId != null &&
          _contextConversationId == conversationId &&
          _contextSystemPrompt == prompt;
      _contextConversationId = conversationId;
      _contextSystemPrompt = prompt;
      await for (final chunk in engine.create(
        _engineMessages(context, prompt),
        params: GenerationParams(
          reusePromptPrefix: reusePromptPrefix,
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
          onContext?.call(
            ContextUsage(
              promptTokens: usage.promptTokens,
              responseTokens: usage.completionTokens,
              contextSize: configuration.contextSize,
              omittedMessageIds: List.unmodifiable(omitted.map((m) => m.id)),
              omittedAttachmentNames: List.unmodifiable(
                omitted
                    .map((m) => m.attachment?.name)
                    .whereType<String>()
                    .toSet(),
              ),
            ),
          );
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
    } on GpuAccelerationFailure {
      await _discardAfterFailure();
      rethrow;
    } on LlamaException {
      await _discardAfterFailure();
      rethrow;
    } finally {
      _active = false;
    }
  }

  @override
  void stop() {
    _stopped = true;
    final signal = _stopSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    _engine?.cancelGeneration();
  }

  Future<void> _discardAfterFailure() async {
    try {
      await _discardEngine();
    } catch (_) {}
  }

  @override
  Future<void> unload() async {
    if (_active) throw StateError('Najpierw zatrzymaj generowanie.');
    await _discardEngine();
  }

  Future<void> _discardEngine() async {
    try {
      await _pendingLoad;
    } catch (_) {}
    final engine = _engine;
    _engine = null;
    _loadedPath = null;
    _contextConversationId = null;
    _loadedConfiguration = null;
    await engine?.dispose();
  }
}
