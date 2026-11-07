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
  }) async {
    final turns = <ContextMessage>[];
    for (final message in history.where(
      (message) => message.text.trim().isNotEmpty,
    )) {
      if (turns.isNotEmpty && turns.last.role == message.role) {
        final previous = turns.removeLast();
        turns.add(
          ContextMessage(message.role, '${previous.text}\n\n${message.text}'),
        );
      } else {
        turns.add(ContextMessage(message.role, message.text));
      }
    }
    while (turns.isNotEmpty) {
      if (isCancelled?.call() ?? false) return [];
      final count = await countTokens(List.unmodifiable(turns));
      if (isCancelled?.call() ?? false) return [];
      if (count <= promptBudget) return List.unmodifiable(turns);
      if (turns.length == 1) throw ChatContextTooLong();
      turns.removeAt(0);
      while (turns.length > 1 && turns.first.role != ChatRole.user) {
        turns.removeAt(0);
      }
    }
    return [];
  }
}
