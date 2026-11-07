import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/conversation_view.dart';

void main() {
  group('Message text selection', () {
    for (final copy in [false, true]) {
      testWidgets(
        copy
            ? 'Copies selected message text to the clipboard'
            : 'Long press exposes the copy action',
        (tester) async {
          String? copied;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
              }
              return null;
            },
          );
          final date = DateTime.utc(2026);
          final conversation = ConversationController(
            Conversation(id: 1, createdAt: date, updatedAt: date),
            messages: [
              ChatMessage(
                id: 'message',
                conversationId: 1,
                authorId: ChatAuthors.assistant,
                text: '**Bielik**',
                createdAt: date,
              ),
            ],
            onDraftChanged: (_) {},
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ConversationView(
                  conversation: conversation,
                  onMessageSend: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.longPress(find.text('Bielik', findRichText: true).first);
          await tester.pumpAndSettle();
          expect(find.text('Copy'), findsOneWidget);
          if (copy) {
            await tester.tap(find.text('Copy'));
            await tester.pumpAndSettle();
            expect(copied, 'Bielik');
          }
          await tester.pumpWidget(const SizedBox.shrink());
          conversation.dispose();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        },
      );
    }
  });
}
