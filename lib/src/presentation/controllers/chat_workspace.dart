import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace() {
    newChat();
  }

  final List<ConversationController> _conversations = [];
  int _nextId = 0;
  int _messageSequence = 0;
  late ConversationController _selected;

  List<ConversationController> get conversations => List.unmodifiable(_conversations);
  ConversationController get selected => _selected;

  void newChat() {
    _selected = ConversationController(_nextId++);
    _conversations.insert(0, _selected);
    notifyListeners();
  }

  void selectConversation(ConversationController conversation) {
    _selected = conversation;
    notifyListeners();
  }

  void deleteConversation(ConversationController conversation) {
    if (!_conversations.remove(conversation)) return;

    if (_conversations.isEmpty) {
      _selected = ConversationController(_nextId++);
      _conversations.add(_selected);
    } else if (_selected == conversation) {
      _selected = _conversations.first;
    }

    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      conversation.dispose();
    });
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
