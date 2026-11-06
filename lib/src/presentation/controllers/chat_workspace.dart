import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace(this.repository);

  final ChatRepository repository;
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
  bool get busy => _busy;
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

  Future<void> deleteConversation(ConversationController conversation) {
    if (!_conversations.contains(conversation) || _disposed) return Future.value();
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
    if (message.isEmpty || !ready || _disposed || _sending) return Future.value();
    final target = selected;
    final revision = target.draftRevision;
    _sending = true;
    _notify();
    return _runAction(() async {
      try {
        if (!_conversations.contains(target)) return;
        final title = target.hasMessages
            ? null
            : message.replaceAll(RegExp(r'\s+'), ' ').characters.take(40).toString();
        final saved = await repository.addMessage(
          conversationId: target.id,
          authorId: 'local-user',
          text: message,
          conversationTitle: title,
        );
        if (_disposed) return;
        await target.addMessage(
          saved,
          submittedDraftRevision: revision,
          title: title,
        );
      } finally {
        _sending = false;
      }
    }, errorMessage: 'Nie udało się zapisać wiadomości. Tekst pozostał w polu wpisywania.');
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
    unawaited(flush().then((_) {
      for (final conversation in _conversations) {
        conversation.dispose();
      }
      _conversations.clear();
    }));
    super.dispose();
  }
}
