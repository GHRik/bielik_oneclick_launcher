import 'package:material_ui/material_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../models/conversation.dart';

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace() {
    newChat();
  }

  final List<Conversation> _conversations = [];
  int _nextId = 0;
  int _messageSequence = 0;
  late Conversation _selected;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation get selected => _selected;

  void newChat() {
    _selected = Conversation(_nextId++);
    _conversations.insert(0, _selected);
    notifyListeners();
  }

  void selectConversation(Conversation conversation) {
    _selected = conversation;
    notifyListeners();
  }

  void sendMessage(String text) {
    final message = text.trim();
    if (message.isEmpty) return;

    _selected.controller.insertMessage(
      TextMessage(
        id: 'message-${_messageSequence++}',
        authorId: 'local-user',
        createdAt: DateTime.now().toUtc(),
        text: message,
      ),
    );
    if (!_selected.hasMessages) {
      _selected.hasMessages = true;
      _selected.title = message.replaceAll(RegExp(r'\s+'), ' ')
          .characters.take(40).toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final conversation in _conversations) {
      conversation.dispose();
    }
    super.dispose();
  }
}
