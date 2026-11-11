import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';

void main() {
  group('Draft length limit', () {
    late ConversationController controller;
    late List<String> saved;
    late int refusals;

    setUp(() {
      saved = [];
      refusals = 0;
      final now = DateTime.utc(2026);
      controller = ConversationController(
        Conversation(id: 1, createdAt: now, updatedAt: now),
        messages: const [],
        onDraftChanged: saved.add,
        onDraftLimitExceeded: () => refusals++,
      );
    });
    tearDown(() => controller.dispose());

    test('Accepts a draft that reaches the limit', () {
      final draft = 'a' * Conversation.maxDraftLength;
      controller.draft.text = draft;

      expect(controller.draft.text, draft);
      expect(saved, [draft]);
      expect(refusals, 0);
    });

    test('Refuses an edit past the limit and keeps the previous draft', () {
      controller.draft.text = 'Kept';
      controller.draft.text = 'a' * (Conversation.maxDraftLength + 1);

      expect(controller.draft.text, 'Kept');
      expect(saved, ['Kept']);
      expect(refusals, 1);
    });

    test('Keeps an unsent message when it returns to a full draft', () async {
      await controller.showPendingMessage('Unsent question', null);
      controller.draft.text = 'a' * Conversation.maxDraftLength;
      await controller.restorePendingMessage();

      expect(controller.draft.text, startsWith('Unsent question\n\naaa'));
      expect(controller.draft.text.length, Conversation.maxDraftLength);
      expect(saved.last.length, Conversation.maxDraftLength);
      expect(refusals, 0);
    });
  });
}
