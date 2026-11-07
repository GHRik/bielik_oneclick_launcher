import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/formatters/storage_size_formatter.dart';
import 'package:bielik_oneclick_launcher/src/presentation/sidebars/widgets/conversation_tile.dart';

void main() {
  group('Storage size formatting', () {
    for (final entry in <int, String>{
      999: '999 B',
      1000: '1,0 KB',
      1000000: '1,0 MB',
      1000000000: '1,0 GB',
    }.entries) {
      test('Formats ${entry.key} bytes as ${entry.value}', () {
        expect(StorageSizeFormatter.format(entry.key), entry.value);
      });
    }
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

  group('Conversation storage size in the sidebar', () {
    late ConversationController conversation;

    Future<void> showTile(WidgetTester tester) async {
      final now = DateTime.utc(2026);
      conversation = ConversationController(
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
      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
    }

    tearDown(() => conversation.dispose());

    testWidgets('Counts title, draft and message bytes', (tester) async {
      await showTile(tester);

      expect(conversation.contentSizeBytes, 14);
      expect(find.text('~14 B'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Places the size before the delete button', (tester) async {
      await showTile(tester);

      expect(
        tester.getCenter(find.text('~14 B')).dx,
        lessThan(tester.getCenter(find.byIcon(Icons.delete_outline)).dx),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Updates the size after editing the draft', (tester) async {
      await showTile(tester);

      conversation.draft.text = 'aaa';
      await tester.pump();

      expect(find.text('~13 B'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'Updates the size after sending a message and changing the title',
      (tester) async {
        await showTile(tester);
        await conversation.addMessage(
          ChatMessage(
            id: '2',
            conversationId: 1,
            authorId: 'local-user',
            text: 'ą🙂',
            createdAt: DateTime.utc(2026),
          ),
          submittedDraftRevision: conversation.draftRevision,
          title: 'Nowy',
        );
        await tester.pump();

        expect(find.text('~18 B'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
