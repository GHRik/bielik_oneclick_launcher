import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

void main() {
  test('Attachment content precedes the user task in the model prompt', () {
    final message = ChatMessage(
      id: '1',
      conversationId: 1,
      authorId: ChatAuthors.user,
      text: 'Streść dokument w trzech punktach.',
      createdAt: DateTime.utc(2026),
      attachment: const TextAttachment(
        name: 'facts.txt',
        text: 'Źródło dokumentu.',
        sizeBytes: 18,
      ),
    );
    expect(message.promptText, endsWith(message.text));
    expect(
      message.promptText.indexOf('Źródło dokumentu.'),
      lessThan(message.promptText.indexOf(message.text)),
    );
  });

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
