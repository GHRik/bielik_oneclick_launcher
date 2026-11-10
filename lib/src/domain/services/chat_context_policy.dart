import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';

class ContextMessage {
  const ContextMessage(this.role, this.text);
  final ChatRole role;
  final String text;
}

class ChatContextTooLong implements Exception {}

class ChatContextPolicy {
  const ChatContextPolicy({
    this.contextSize = 2048,
    this.responseTokens = 512,
    this.safetyTokens = 32,
  }) : assert(contextSize > responseTokens + safetyTokens);

  final int contextSize;
  final int responseTokens;
  final int safetyTokens;
  int get promptBudget => contextSize - responseTokens - safetyTokens;

  Future<List<ContextMessage>> prepare(
    List<ChatMessage> history, {
    required Future<int> Function(List<ContextMessage>) countTokens,
    bool Function()? isCancelled,
    void Function(List<ChatMessage>)? onOmittedMessages,
  }) async {
    final turns = <ContextMessage>[];
    final sources = <List<ChatMessage>>[];
    final omitted = <ChatMessage>[];
    void removeOldest() {
      turns.removeAt(0);
      omitted.addAll(sources.removeAt(0));
    }

    for (final message in history.where(
      (message) => message.promptText.trim().isNotEmpty,
    )) {
      if (turns.isNotEmpty && turns.last.role == message.role) {
        sources.last.add(message);
        final previous = turns.removeLast();
        turns.add(
          ContextMessage(
            message.role,
            '${previous.text}\n\n${message.promptText}',
          ),
        );
      } else {
        sources.add([message]);
        turns.add(ContextMessage(message.role, message.promptText));
      }
    }
    while (turns.isNotEmpty) {
      if (isCancelled?.call() ?? false) return [];
      final count = await countTokens(List.unmodifiable(turns));
      if (isCancelled?.call() ?? false) return [];
      if (count <= promptBudget) {
        onOmittedMessages?.call(List.unmodifiable(omitted));
        return List.unmodifiable(turns);
      }
      if (turns.length == 1) throw ChatContextTooLong();
      removeOldest();
      while (turns.length > 1 && turns.first.role != ChatRole.user) {
        removeOldest();
      }
    }
    return [];
  }
}
