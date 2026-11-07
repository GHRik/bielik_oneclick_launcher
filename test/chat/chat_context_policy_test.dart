import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

ChatMessage _message(String text, String author) => ChatMessage(
  id: text,
  conversationId: 1,
  authorId: author,
  text: text,
  createdAt: DateTime.utc(2026),
);

void main() {
  group('Inference context normalization', () {
    test('Merges consecutive messages with the same role', () async {
      final context = await const ChatContextPolicy().prepare([
        _message('First', ChatAuthors.user),
        _message('Second', ChatAuthors.user),
      ], countTokens: (_) async => 10);

      expect(context.single.text, 'First\n\nSecond');
      expect(context.single.role, ChatRole.user);
    });

    test('Ignores empty assistant replies', () async {
      final context = await const ChatContextPolicy().prepare([
        _message('Question', ChatAuthors.user),
        _message('', ChatAuthors.assistant),
      ], countTokens: (_) async => 10);

      expect(context.map((message) => message.text), ['Question']);
    });

    test('Leaves persisted history unchanged', () async {
      final history = [
        _message('First', ChatAuthors.user),
        _message('', ChatAuthors.assistant),
        _message('Second', ChatAuthors.user),
        _message('Reply', ChatAuthors.assistant),
      ];
      final original = List<ChatMessage>.of(history);

      await const ChatContextPolicy().prepare(
        history,
        countTokens: (_) async => 10,
      );

      expect(history, orderedEquals(original));
    });
  });

  group('Inference context budget', () {
    const policy = ChatContextPolicy(
      contextSize: 60,
      responseTokens: 30,
      safetyTokens: 5,
    );

    test('Reserves tokens for the response and safety margin', () {
      expect(policy.promptBudget, 25);
    });

    test(
      'Removes the oldest complete turn when the prompt is too large',
      () async {
        final context = await policy.prepare([
          _message('Old question', ChatAuthors.user),
          _message('Old reply', ChatAuthors.assistant),
          _message('New question', ChatAuthors.user),
        ], countTokens: (messages) async => messages.length * 20);

        expect(context.single.text, 'New question');
      },
    );

    test('Rejects a single oversized question', () async {
      await expectLater(
        const ChatContextPolicy().prepare([
          _message('Too long', ChatAuthors.user),
        ], countTokens: (_) async => 10000),
        throwsA(isA<ChatContextTooLong>()),
      );
    });

    test('Returns no context when cancelled during token counting', () async {
      var stopped = false;
      final context = await const ChatContextPolicy().prepare(
        [_message('Question', ChatAuthors.user)],
        isCancelled: () => stopped,
        countTokens: (_) async {
          stopped = true;
          return 1;
        },
      );

      expect(context, isEmpty);
    });
  });
}
