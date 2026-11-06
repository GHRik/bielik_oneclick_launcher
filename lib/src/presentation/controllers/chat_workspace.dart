import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace(this.repository, {LlmRepository? llmRepository}) : _llm = llmRepository;

  final ChatRepository repository;
  final LlmRepository? _llm;
  BielikModel? _model;
  ConversationController? _generationTarget;
  Future<void>? _generationTask;
  Future<void>? _releaseTask;
  bool _stopRequested = false;
  bool _releasing = false;
  LlmStage? _stage;
  String? get modelName => _model?.name;
  String get generationStatus => _stopRequested
      ? 'Zatrzymywanie…'
      : _stage == LlmStage.loading ? 'Ładowanie modelu…' : 'Bielik pisze…';
  String? get generatingTitle => _generationTarget?.title;

  void useModel(BielikModel model) {
    if (_sending || _releasing) throw StateError('Model jest zajęty.');
    _model = model;
    _notify();
  }

  Future<void> stopGeneration() async {
    if (!_sending) return;
    _stopRequested = true;
    _llm?.stop();
    _notify();
    await _generationTask;
  }

  Future<void> releaseModel() {
    if (_releaseTask != null) return _releaseTask!;
    _releasing = true;
    _notify();
    final task = () async {
      try {
        await stopGeneration();
        await _llm?.unload();
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
  String? _error;

  List<ConversationController> get conversations => List.unmodifiable(_conversations);
  ConversationController get selected => _selected!;
  bool get ready => _selected != null;
  bool get loading => _loading;
  bool get busy => _busy || _releasing;
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
      onDraftChanged: (draft) {
        unawaited(_enqueue(() async {
          if (_conversations.contains(controller)) {
            await repository.saveDraft(controller.id, draft);
          }
        }, errorMessage: 'Nie udało się zapisać szkicu wiadomości.'));
      },
    );
    return controller;
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
          conversations.map((conversation) => repository.getMessages(conversation.id)),
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
    unawaited(task.then((_) {
      if (!ready) _initialization = null;
    }));
    return task;
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
    _notify();
  }

  Future<void> deleteConversation(ConversationController conversation) async {
    if (!_conversations.contains(conversation) || _disposed) return;
    if (_generationTarget == conversation) await stopGeneration();
    return _runAction(() async {
      if (!_conversations.contains(conversation)) return;
      await repository.deleteConversation(conversation.id);
      if (_disposed) return;
      _conversations.remove(conversation);
      if (_conversations.isEmpty) {
        _selected = null;
        _initialization = null;
        _notify();
        WidgetsBinding.instance.addPostFrameCallback((_) => conversation.dispose());
        final replacement = await repository.createConversation();
        if (_disposed) return;
        _selected = _controller(replacement, []);
        _conversations.add(_selected!);
      } else {
        if (_selected == conversation) _selected = _conversations.first;
        _notify();
        WidgetsBinding.instance.addPostFrameCallback((_) => conversation.dispose());
      }
    }, errorMessage: 'Nie udało się zakończyć usuwania rozmowy. Spróbuj ponownie.');
  }

  Future<void> sendMessage(String text) {
    final message = text.trim();
    if (message.isEmpty || !ready || _disposed || _sending || _releasing) return Future.value();
    if (_llm != null && _model?.file == null) {
      _error = 'Wybierz model na ekranie głównym.';
      _notify();
      return Future.value();
    }
    final target = selected;
    final revision = target.draftRevision;
    _sending = true;
    _stopRequested = false;
    _generationTarget = target;
    _stage = null;
    _notify();
    final task = _sendAndGenerate(target, message, revision);
    _generationTask = task;
    return task;
  }

  Future<void> _sendAndGenerate(
    ConversationController target, String message, int revision,
  ) async {
    var savedUser = false;
    try {
      await _runAction(() async {
        if (!_conversations.contains(target)) return;
        final title = target.hasMessages
            ? null
            : message.replaceAll(RegExp(r'\s+'), ' ').characters.take(40).toString();
        final saved = await repository.addMessage(
          conversationId: target.id, authorId: 'local-user',
          text: message, conversationTitle: title,
        );
        if (_disposed) return;
        await target.addMessage(saved, submittedDraftRevision: revision, title: title);
        savedUser = true;
      }, errorMessage: 'Nie udało się zapisać wiadomości. Tekst pozostał w polu wpisywania.');
      if (savedUser && !_disposed && !_stopRequested && _llm != null) {
        await _generate(target);
      }
    } catch (error) {
      if (!_stopRequested) _error = 'Nie udało się wygenerować odpowiedzi: $error';
    } finally {
      _sending = false;
      _generationTarget = null;
      _stage = null;
      _notify();
    }
  }

  Future<void> _generate(ConversationController target) async {
    final history = target.messages;
    final buffer = StringBuffer();
    String? responseId;
    var lastSave = DateTime.now();
    try {
      await for (final fragment in _llm!.generate(
        _model!.file!, history,
        onStage: (stage) { _stage = stage; _notify(); },
      )) {
        if (_stopRequested || _disposed) break;
        buffer.write(fragment);
        if (responseId == null) {
          final saved = await repository.addMessage(
            conversationId: target.id, authorId: 'bielik', text: buffer.toString(),
          );
          responseId = saved.id;
          await target.addMessage(saved);
        } else {
          await target.updateMessage(responseId, buffer.toString());
          if (DateTime.now().difference(lastSave).inMilliseconds >= 500) {
            await repository.updateMessage(responseId, buffer.toString());
            lastSave = DateTime.now();
          }
        }
      }
      if (responseId == null && !_stopRequested && !_disposed) {
        throw StateError('Model nie zwrócił odpowiedzi.');
      }
    } finally {
      _llm!.stop();
      if (responseId != null) {
        await repository.updateMessage(responseId, buffer.toString());
      }
    }
  }

  Future<void> flush() async {
    while (true) {
      final pending = _pending;
      await pending;
      if (identical(pending, _pending)) return;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopRequested = true;
    _llm?.stop();
    unawaited(() async {
      await _generationTask;
      await flush();
      try {
        await _llm?.unload();
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
