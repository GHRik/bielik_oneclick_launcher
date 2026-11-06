import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/formatters/storage_size_formatter.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/conversation_tile.dart';

void main() {
  test('Formats decimal storage units without counting characters as bytes', () {
    expect(StorageSizeFormatter.format(999), '999 B');
    expect(StorageSizeFormatter.format(1000), '1,0 KB');
    expect(StorageSizeFormatter.format(1000000), '1,0 MB');
    expect(StorageSizeFormatter.format(1000000000), '1,0 GB');
    final now = DateTime.utc(2026);
    expect(
      ChatMessage(
        id: '1',
        conversationId: 1,
        authorId: 'local-user',
        text: 'ą🙂',
        createdAt: now,
      ).contentSizeBytes,
      6,
    );
  });

  testWidgets('Shows UTF-8 size beside the bin and updates it as content changes',
      (tester) async {
    final now = DateTime.utc(2026);
    final conversation = ConversationController(
      Conversation(
        id: 1,
        title: 'ą',
        draft: '🙂',
        createdAt: now,
        updatedAt: now,
      ),
      messages: [
        ChatMessage(
          id: '1',
          conversationId: 1,
          authorId: 'local-user',
          text: 'żółć',
          createdAt: now,
        ),
      ],
      onDraftChanged: (_) {},
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 280,
          child: ConversationTile(
            conversation: conversation,
            selected: true,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    ));
    expect(conversation.contentSizeBytes, 14);
    expect(find.text('~14 B'), findsOneWidget);
    expect(
      tester.getCenter(find.text('~14 B')).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.delete_outline)).dx),
    );
    conversation.draft.text = 'aaa';
    await tester.pump();
    expect(find.text('~13 B'), findsOneWidget);
    await conversation.addMessage(
      ChatMessage(
        id: '2',
        conversationId: 1,
        authorId: 'local-user',
        text: 'ą🙂',
        createdAt: now,
      ),
      submittedDraftRevision: conversation.draftRevision,
      title: 'Nowy',
    );
    await tester.pump();
    expect(find.text('~18 B'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    conversation.dispose();
  });
}
