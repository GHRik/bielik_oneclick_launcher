import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

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
  group('Omitted history reporting', () {
    test('Reports original messages from merged and removed turns', () async {
      List<ChatMessage>? omitted;
      final history = [
        _message('Old first', ChatAuthors.user),
        _message('Old second', ChatAuthors.user),
        _message('Old reply', ChatAuthors.assistant),
        _message('New question', ChatAuthors.user),
      ];
      await const ChatContextPolicy(
        contextSize: 60,
        responseTokens: 30,
        safetyTokens: 5,
      ).prepare(
        history,
        countTokens: (messages) async => messages.length * 20,
        onOmittedMessages: (messages) => omitted = messages,
      );
      expect(omitted, orderedEquals(history.take(3)));
    });

    test('Reports no omissions when the complete history fits', () async {
      List<ChatMessage>? omitted;
      await const ChatContextPolicy().prepare(
        [_message('Question', ChatAuthors.user)],
        countTokens: (_) async => 1,
        onOmittedMessages: (messages) => omitted = messages,
      );
      expect(omitted, isEmpty);
    });

    test('Does not publish omissions for a rejected prompt', () async {
      var reported = false;
      await expectLater(
        const ChatContextPolicy().prepare(
          [
            _message('Old', ChatAuthors.user),
            _message('Reply', ChatAuthors.assistant),
            _message('Too long', ChatAuthors.user),
          ],
          countTokens: (_) async => 10000,
          onOmittedMessages: (_) => reported = true,
        ),
        throwsA(isA<ChatContextTooLong>()),
      );
      expect(reported, isFalse);
    });

    test('Does not publish omissions after cancellation', () async {
      var stopped = false;
      var reported = false;
      await const ChatContextPolicy().prepare(
        [_message('Question', ChatAuthors.user)],
        isCancelled: () => stopped,
        countTokens: (_) async {
          stopped = true;
          return 1;
        },
        onOmittedMessages: (_) => reported = true,
      );
      expect(reported, isFalse);
    });
  });

  test('Includes attachment-only messages in the model context', () async {
    final message = ChatMessage(
      id: 'file',
      conversationId: 1,
      authorId: ChatAuthors.user,
      text: '',
      createdAt: DateTime.utc(2026),
      attachment: const TextAttachment(
        name: 'notes.txt',
        text: 'Important source',
        sizeBytes: 16,
      ),
    );
    final context = await const ChatContextPolicy().prepare([
      message,
    ], countTokens: (_) async => 10);
    expect(context.single.text, contains('Important source'));
  });

  test(
    'Counts the attachment content when enforcing the context budget',
    () async {
      final message = ChatMessage(
        id: 'file',
        conversationId: 1,
        authorId: ChatAuthors.user,
        text: 'Question',
        createdAt: DateTime.utc(2026),
        attachment: TextAttachment(
          name: 'large.txt',
          text: 'x' * 3000,
          sizeBytes: 3000,
        ),
      );
      await expectLater(
        const ChatContextPolicy().prepare([
          message,
        ], countTokens: (messages) async => messages.single.text.length),
        throwsA(isA<ChatContextTooLong>()),
      );
    },
  );

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
  test(
    'ChatContextPolicy reserves the configured reply and safety budgets',
    () {
      const policy = ChatContextPolicy(
        contextSize: 4096,
        responseTokens: 1024,
        safetyTokens: 32,
      );

      expect(policy.promptBudget, 3040);
    },
  );
}
