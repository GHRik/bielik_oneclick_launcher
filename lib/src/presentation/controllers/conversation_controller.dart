import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';

class ConversationController {
  ConversationController(int id) : _conversation = Conversation(id: id);

  Conversation _conversation;
  final controller = InMemoryChatController();
  final draft = TextEditingController();
  bool hasMessages = false;

  Conversation get conversation => _conversation;
  int get id => _conversation.id;
  String get title => _conversation.title;
  set title(String value) {
    _conversation = _conversation.copyWith(title: value);
  }

  void dispose() {
    controller.dispose();
    draft.dispose();
  }
}
