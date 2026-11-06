import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';

sealed class ChatUpdate {
  const ChatUpdate();
}

class ChatMessageSaved extends ChatUpdate {
  const ChatMessageSaved(this.message, {this.title});

  final ChatMessage message;
  final String? title;
}

class ChatMessageUpdated extends ChatUpdate {
  const ChatMessageUpdated(this.id, this.text);

  final String id;
  final String text;
}
