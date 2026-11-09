import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

class ComputeRoutingLlmRepository implements LlmRepository {
  ComputeRoutingLlmRepository({required this.cpu, required this.createGpu});
  final LlmRepository cpu;
  final LlmRepository Function() createGpu;
  LlmRepository? _gpu;
  LlmRepository? _selected;
  bool _active = false;
  bool _stopped = false;

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
  }) async* {
    if (_active) throw StateError('Generowanie już trwa.');
    _active = true;
    _stopped = false;
    final useGpu = computeMode == LlmComputeMode.gpu;
    try {
      final next = useGpu ? (_gpu ??= createGpu()) : cpu;
      if (_selected != null && !identical(_selected, next)) {
        await _selected!.unload();
      }
      _selected = next;
      if (_stopped) return;
      await for (final text in next.generate(
        model,
        history,
        onStage: onStage,
        computeMode: computeMode,
        onLoaded: onLoaded,
        onContext: onContext,
      )) {
        yield text;
      }
    } catch (error) {
      if (useGpu) {
        await _gpu?.unload();
        _gpu = null;
        _selected = null;
        if (error is GpuAccelerationFailure) rethrow;
        throw GpuAccelerationFailure(error.toString());
      }
      rethrow;
    } finally {
      _active = false;
    }
  }

  @override
  void stop() {
    _stopped = true;
    _selected?.stop();
  }

  @override
  Future<void> unload() async {
    if (_active) throw StateError('Najpierw zatrzymaj generowanie.');
    await cpu.unload();
    await _gpu?.unload();
    _gpu = null;
    _selected = null;
  }
}
