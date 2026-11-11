import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';

void main() {
  group('Draft length limit', () {
    test('Keeps a draft at the limit unchanged', () {
      final draft = 'a' * Conversation.maxDraftLength;
      expect(Conversation.clampDraft(draft), same(draft));
    });

    test('Cuts a longer draft to the limit', () {
      final draft = 'a' * (Conversation.maxDraftLength + 1);
      expect(
        Conversation.clampDraft(draft).length,
        Conversation.maxDraftLength,
      );
    });

    test('Does not split a surrogate pair at the limit', () {
      final draft = '${'a' * (Conversation.maxDraftLength - 1)}😀';
      expect(
        Conversation.clampDraft(draft),
        'a' * (Conversation.maxDraftLength - 1),
      );
    });
  });
}
