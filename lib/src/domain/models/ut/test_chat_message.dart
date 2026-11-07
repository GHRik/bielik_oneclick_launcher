import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';

void main() {
  test('Message size counts UTF-8 bytes rather than characters', () {
    final message = ChatMessage(
      id: '1',
      conversationId: 1,
      authorId: 'local-user',
      text: 'ą🙂',
      createdAt: DateTime.utc(2026),
    );

    expect(message.contentSizeBytes, 6);
  });
}
