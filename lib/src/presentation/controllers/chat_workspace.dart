import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_service.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace(
    this.repository, {
    LlmRepository? llmRepository,
    this.deviceResourcesRepository,
  }) : _chatService = ChatService(repository, llmRepository: llmRepository);

  Timer? _idleReleaseTimer;
  bool _retainModel = true;

  void retainModel() {
    _retainModel = true;
    _idleReleaseTimer?.cancel();
  }

  void releaseModelWhenIdle() {
    _retainModel = false;
    _scheduleIdleRelease();
  }

  void _scheduleIdleRelease() {
    _idleReleaseTimer?.cancel();
    if (_disposed || _retainModel || _sending || _releasing) return;
    _idleReleaseTimer = Timer(const Duration(minutes: 2), () {
      unawaited(releaseModel());
    });
  }

  final DeviceResourcesRepository? deviceResourcesRepository;
  bool _lowMemory = false;
  int _memoryRead = 0;
  bool get showMemoryWarning =>
      _stage == LlmStage.loading && _lowMemory && !_stopRequested;

  Future<void> _checkLoadingMemory() async {
    final request = ++_memoryRead;
    final model = _model;
    if (model == null || deviceResourcesRepository == null) return;
    try {
      final resources = await deviceResourcesRepository!.read();
      if (_disposed || request != _memoryRead || _stage != LlmStage.loading) {
        return;
      }
      final available = resources.availableRamGb;
      _lowMemory = available != null && available < model.requiredFreeRamGb;
      _notify();
    } catch (_) {}
  }

  final ChatRepository repository;
  final ChatService _chatService;
  final Map<int, ContextUsage> _contextUsage = {};
  ContextUsage? get contextUsage => _contextUsage[_selected?.id];
  BielikModel? _model;
  LlmComputeMode _computeMode = LlmComputeMode.cpu;
  LlmRuntimeInfo? _runtimeInfo;
  LlmRuntimeInfo? get runtimeInfo => _runtimeInfo;
  String get computeStatus {
    final runtime = _runtimeInfo;
    if (runtime != null) {
      return runtime.mode == LlmComputeMode.gpu
          ? 'GPU · ${runtime.backend}'
          : 'CPU';
    }
    return '${_computeMode == LlmComputeMode.gpu ? 'GPU' : 'CPU'} · niezaładowany';
  }

  ConversationController? _generationTarget;
  String? _streamingMessageId;
  String? get streamingMessageId =>
      _selected == _generationTarget ? _streamingMessageId : null;
  Future<void>? _generationTask;
  Future<void>? _releaseTask;
  bool _stopRequested = false;
  bool _releasing = false;
  LlmStage? _stage;
  String? get modelName => _model?.name;
  String get generationStatus => _stopRequested
      ? 'Zatrzymywanie…'
      : _stage == LlmStage.loading
      ? 'Ładowanie modelu…'
      : _stage == LlmStage.generating
      ? 'Bielik pisze…'
      : 'Bielik myśli…';
  String? get generatingTitle => _generationTarget?.title;

  void useModel(
    BielikModel model, {
    LlmComputeMode computeMode = LlmComputeMode.cpu,
  }) {
    if (_model == model && _computeMode == computeMode) return;
    if (_sending || _releasing) throw StateError('Model jest zajęty.');
    _contextUsage.clear();
    _model = model;
    _computeMode = computeMode;
    _runtimeInfo = null;
    _notify();
  }

  Future<void> stopGeneration() async {
    if (!_sending) return;
    _stopRequested = true;
    _chatService.stop();
    _notify();
    await _generationTask;
  }

  Future<void> releaseModel() {
    _idleReleaseTimer?.cancel();
    if (_releaseTask != null) return _releaseTask!;
    _releasing = true;
    _notify();
    final task = () async {
      try {
        await stopGeneration();
        await _chatService.unload();
        _runtimeInfo = null;
        _contextUsage.clear();
      } catch (error) {
        _error = 'Nie udało się zwolnić modelu: $error';
      } finally {
        _releasing = false;
        _releaseTask = null;
        _notify();
      }
    }();
    _releaseTask = task;
    return task;
  }

  final List<ConversationController> _conversations = [];
  ConversationController? _selected;
  Future<void> _pending = Future.value();
  Future<void>? _initialization;
  bool _disposed = false;
  bool _loading = true;
  bool _busy = false;
  bool _sending = false;
  bool _pickingAttachment = false;
  bool get pickingAttachment => _pickingAttachment;
  String? _error;

  List<ConversationController> get conversations =>
      List.unmodifiable(_conversations);
  ConversationController get selected => _selected!;
  bool get ready => _selected != null;
  bool get loading => _loading;
  bool get busy => _busy || _releasing || _pickingAttachment;
  bool get sending => _sending;
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void dismissError() {
    _error = null;
    _notify();
  }

  Future<void> _enqueue(
    Future<void> Function() action, {
    required String errorMessage,
  }) {
    final task = _pending.then((_) async {
      try {
        await action();
      } catch (_) {
        _error = errorMessage;
        _notify();
      }
    });
    _pending = task;
    return task;
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String errorMessage,
  }) => _enqueue(() async {
    _busy = true;
    _error = null;
    _notify();
    try {
      await action();
    } finally {
      _busy = false;
      _notify();
    }
  }, errorMessage: errorMessage);

  ConversationController _controller(
    Conversation conversation,
    List<ChatMessage> messages,
  ) {
    late final ConversationController controller;
    controller = ConversationController(
      conversation,
      messages: messages,
      onAttachmentChanged: (attachment) {
        unawaited(
          _enqueue(() async {
            if (_conversations.contains(controller)) {
              await _chatService.saveDraftAttachment(controller.id, attachment);
            }
          }, errorMessage: 'Nie udało się zapisać załącznika.'),
        );
      },
      onDraftChanged: (draft) {
        unawaited(
          _enqueue(() async {
            if (_conversations.contains(controller)) {
              await _chatService.saveDraft(controller.id, draft);
            }
          }, errorMessage: 'Nie udało się zapisać szkicu wiadomości.'),
        );
      },
    );
    return controller;
  }

  Future<bool> importText(String text) async {
    if (_disposed || text.trim().isEmpty || text.length > 65536) return false;
    _error = null;
    await initialize();
    await flush();
    if (_disposed || !ready || _conversations.isEmpty) return false;
    final target = _conversations.first;
    selectConversation(target);
    final previous = target.draft.text;
    target.draft.value = TextEditingValue(
      text: previous.isEmpty ? text : '$previous\n\n$text',
      selection: TextSelection.collapsed(
        offset: previous.isEmpty
            ? text.length
            : previous.length + 2 + text.length,
      ),
    );
    target.offerTextActions();
    await flush();
    return !_disposed && _error == null;
  }

  Future<void> initialize() {
    if (_initialization != null) return _initialization!;
    _loading = true;
    final task = _runAction(() async {
      try {
        var conversations = await repository.getConversations();
        if (conversations.isEmpty) {
          conversations = [await repository.createConversation()];
        }
        final messages = await Future.wait(
          conversations.map(
            (conversation) => repository.getMessages(conversation.id),
          ),
        );
        if (_disposed) return;
        for (var i = 0; i < conversations.length; i++) {
          _conversations.add(_controller(conversations[i], messages[i]));
        }
        _selected = _conversations.first;
      } finally {
        _loading = false;
      }
    }, errorMessage: 'Nie udało się wczytać rozmów. Spróbuj ponownie.');
    _initialization = task;
    unawaited(
      task.then((_) {
        if (!ready) _initialization = null;
      }),
    );
    return task;
  }

  Future<void> pickAttachment(AttachmentRepository repository) async {
    if (!ready || _disposed || busy || sending) return;
    final target = selected;
    _pickingAttachment = true;
    _error = null;
    _notify();
    try {
      final attachment = await repository.pickTextAttachment();
      if (!_disposed && attachment != null && _conversations.contains(target)) {
        target.setAttachment(attachment);
        await flush();
      }
    } on AttachmentException catch (error) {
      _error = switch (error.failure) {
        AttachmentFailure.unsupportedType =>
          'Na razie można dołączać tylko pliki TXT.',
        AttachmentFailure.tooLarge =>
          'Plik TXT jest za duży. Limit wynosi 64 KiB.',
        AttachmentFailure.invalidEncoding =>
          'Plik nie jest poprawnym tekstem UTF-8. Zapisz go w UTF-8.',
        AttachmentFailure.empty => 'Wybrany plik TXT jest pusty.',
        AttachmentFailure.readFailed => 'Nie udało się odczytać pliku TXT.',
      };
    } catch (_) {
      _error = 'Nie udało się odczytać pliku TXT.';
    } finally {
      _pickingAttachment = false;
      _notify();
    }
  }

  Future<void> newChat() {
    if (!ready || _disposed) return Future.value();
    return _runAction(() async {
      final conversation = await repository.createConversation();
      if (_disposed) return;
      _selected = _controller(conversation, []);
      _conversations.insert(0, _selected!);
    }, errorMessage: 'Nie udało się utworzyć rozmowy.');
  }

  void selectConversation(ConversationController conversation) {
    if (!_conversations.contains(conversation) || _disposed) return;
    _selected = conversation;
    _conversations.remove(conversation);
    _conversations.insert(0, conversation);
    _notify();
    unawaited(
      _enqueue(() async {
        if (_conversations.contains(conversation)) {
          await repository.markConversationUsed(conversation.id);
        }
      }, errorMessage: 'Nie udało się zapisać kolejności rozmów.'),
    );
  }

  Future<void> deleteConversation(ConversationController conversation) async {
    if (!_conversations.contains(conversation) || _disposed) return;
    if (_generationTarget == conversation) await stopGeneration();
    return _runAction(
      () async {
        if (!_conversations.contains(conversation)) return;
        await repository.deleteConversation(conversation.id);
        if (_disposed) return;
        _conversations.remove(conversation);
        _contextUsage.remove(conversation.id);
        if (_conversations.isEmpty) {
          _selected = null;
          _initialization = null;
          _notify();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => conversation.dispose(),
          );
          final replacement = await repository.createConversation();
          if (_disposed) return;
          _selected = _controller(replacement, []);
          _conversations.add(_selected!);
        } else {
          if (_selected == conversation) _selected = _conversations.first;
          _notify();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => conversation.dispose(),
          );
        }
      },
      errorMessage:
          'Nie udało się zakończyć usuwania rozmowy. Spróbuj ponownie.',
    );
  }

  Future<void> sendTextAction(ChatTextAction action) {
    if (!ready || _disposed || busy || sending || !selected.offersTextActions) {
      return Future.value();
    }
    final prompt = action.prompt(
      selected.draft.text,
      hasAttachment: selected.attachment != null,
    );
    return sendMessage(prompt);
  }

  Future<void> sendMessage(String text) {
    final message = text.trim();
    if (!ready ||
        _disposed ||
        _sending ||
        _releasing ||
        _pickingAttachment ||
        (message.isEmpty && selected.attachment == null)) {
      return Future.value();
    }
    if (_chatService.hasLlm && _model?.file == null) {
      _error = 'Wybierz model na ekranie głównym.';
      _notify();
      return Future.value();
    }
    final target = selected;
    selectConversation(target);
    final revision = target.draftRevision;
    _idleReleaseTimer?.cancel();
    final attachmentRevision = target.attachmentRevision;
    final attachment = target.attachment;
    _error = null;
    _sending = true;
    _stopRequested = false;
    _generationTarget = target;
    _stage = null;
    _notify();
    final task = _sendAndGenerate(
      target,
      message,
      revision,
      attachment,
      attachmentRevision,
    );
    _generationTask = task;
    return task;
  }

  Future<void> _sendAndGenerate(
    ConversationController target,
    String message,
    int revision,
    TextAttachment? attachment,
    int attachmentRevision,
  ) async {
    try {
      await target.showPendingMessage(message, attachment);
      await flush();
      if (_disposed || _stopRequested || !_conversations.contains(target)) {
        return;
      }
      await _chatService.send(
        conversationId: target.id,
        text: message,
        attachment: attachment,
        history: target.messages,
        model: _model?.file,
        computeMode: _computeMode,
        onContext: (usage) {
          if (_disposed || !_conversations.contains(target)) return;
          _contextUsage[target.id] = usage;
          _notify();
        },
        onLoaded: (runtime) {
          _runtimeInfo = runtime;
          _notify();
        },
        onStage: (stage) {
          _stage = stage;
          _lowMemory = false;
          _memoryRead++;
          if (stage == LlmStage.loading) unawaited(_checkLoadingMemory());
          _notify();
        },
        onUpdate: (update) async {
          if (_disposed) return;
          switch (update) {
            case ChatMessageSaved():
              if (update.message.role == ChatRole.assistant) {
                _streamingMessageId = update.message.id;
                _notify();
              }
              await target.addMessage(
                update.message,
                submittedAttachmentRevision:
                    update.message.role == ChatRole.user
                    ? attachmentRevision
                    : null,
                submittedDraftRevision: update.message.role == ChatRole.user
                    ? revision
                    : null,
                title: update.title,
              );
            case ChatMessageUpdated():
              await target.updateMessage(update.id, update.text);
          }
        },
      );
    } on UserMessageSaveFailure {
      _error =
          'Nie udało się zapisać wiadomości. Tekst pozostał w polu wpisywania.';
    } on GpuAccelerationFailure catch (error) {
      _runtimeInfo = null;
      if (!_stopRequested) {
        _error =
            'Błąd akceleracji GPU. Wyłącz GPU w konfiguracji, aby użyć CPU. ${error.reason}';
      }
    } on ChatContextTooLong {
      _error =
          'Wiadomość lub załącznik przekracza kontekst modelu. '
          'Treść pozostała do edycji. Skróć tekst albo wybierz mniejszy plik.';
    } on EmptyModelReply {
      if (!_stopRequested) _error = 'Model nie zwrócił odpowiedzi.';
    } catch (error) {
      if (!_stopRequested) {
        _error = 'Nie udało się wygenerować odpowiedzi: $error';
      }
    } finally {
      if (!_disposed && _conversations.contains(target)) {
        if (await target.restorePendingMessage()) await flush();
      }
      _sending = false;
      _streamingMessageId = null;
      _generationTarget = null;
      _stage = null;
      _lowMemory = false;
      _memoryRead++;
      _scheduleIdleRelease();
      _notify();
    }
  }

  Future<void> flush() async {
    while (true) {
      final pending = _pending;
      await pending;
      if (identical(pending, _pending)) {
        await _chatService.flush();
        if (identical(pending, _pending)) return;
      }
    }
  }

  @override
  void dispose() {
    _idleReleaseTimer?.cancel();
    _disposed = true;
    _stopRequested = true;
    _chatService.stop();
    unawaited(() async {
      await _generationTask;
      await flush();
      try {
        await _chatService.unload();
      } catch (error) {
        _error = 'Nie udało się zwolnić modelu: $error';
      } finally {
        for (final conversation in _conversations) {
          conversation.dispose();
        }
        _conversations.clear();
      }
    }());
    super.dispose();
  }
}
