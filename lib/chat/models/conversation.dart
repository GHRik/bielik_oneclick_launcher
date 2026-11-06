import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:material_ui/material_ui.dart';

class Conversation {
  Conversation(this.id);

  final int id;
  final controller = InMemoryChatController();
  final draft = TextEditingController();
  String title = 'Nowa rozmowa';
  bool hasMessages = false;

  void dispose() {
    controller.dispose();
    draft.dispose();
  }
}
