import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

ChatMessage _message(String text, String author) => ChatMessage(
  id: text, conversationId: 1, authorId: author, text: text,
  createdAt: DateTime.utc(2026),
);

void main() {
  test('Merges consecutive roles and ignores empty replies without changing history', () async {
    final history = [
      _message('Pierwsze', ChatAuthors.user),
      _message('', ChatAuthors.assistant),
      _message('Drugie', ChatAuthors.user),
      _message('Odpowiedź', ChatAuthors.assistant),
    ];
    final context = await const ChatContextPolicy().prepare(
      history, countTokens: (_) async => 10,
    );
    expect(context.map((m) => m.text), ['Pierwsze\n\nDrugie', 'Odpowiedź']);
    expect(context.first.role, ChatRole.user);
    expect(history, hasLength(4));
  });

  test('Removes oldest complete turns to respect prompt and reply budgets', () async {
    const policy = ChatContextPolicy(contextSize: 60, responseTokens: 30, safetyTokens: 5);
    final history = [
      _message('Stare pytanie', ChatAuthors.user),
      _message('Stara odpowiedź', ChatAuthors.assistant),
      _message('Nowe pytanie', ChatAuthors.user),
    ];
    final context = await policy.prepare(history, countTokens: (messages) async => messages.length * 20);
    expect(policy.promptBudget, 25);
    expect(context.single.text, 'Nowe pytanie');
    expect(history, hasLength(3));
  });

  test('Rejects a single oversized question', () async {
    await expectLater(
      const ChatContextPolicy().prepare(
        [_message('Za długie', ChatAuthors.user)],
        countTokens: (_) async => 10000,
      ),
      throwsA(isA<ChatContextTooLong>()),
    );
  });

  test('Cancellation during token counting exits without inference context', () async {
    var stopped = false;
    final context = await const ChatContextPolicy().prepare(
      [_message('Pytanie', ChatAuthors.user)],
      isCancelled: () => stopped,
      countTokens: (_) async { stopped = true; return 1; },
    );
    expect(context, isEmpty);
  });
}
