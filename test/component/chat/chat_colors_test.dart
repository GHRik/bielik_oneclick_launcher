import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/theme/landing_page_theme.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/conversation_view.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Chat inherits the app palette in ${brightness.name} mode', (
      tester,
    ) async {
      final date = DateTime.utc(2026);
      final conversation = ConversationController(
        Conversation(id: 1, createdAt: date, updatedAt: date),
        messages: [
          ChatMessage(
            id: 'question',
            conversationId: 1,
            authorId: ChatAuthors.user,
            text: 'Moje pytanie',
            createdAt: date,
          ),
        ],
        onDraftChanged: (_) {},
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        conversation.dispose();
      });
      final theme = landingPageTheme(brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ConversationView(
              conversation: conversation,
              onMessageSend: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chat = tester.widget<Chat>(find.byType(Chat));
      expect(chat.theme!.colors.primary, theme.colorScheme.primary);
      expect(chat.backgroundColor, theme.scaffoldBackgroundColor);
      final bubble = tester.widget<SimpleTextMessage>(
        find.byType(SimpleTextMessage),
      );
      expect(bubble.sentBackgroundColor, theme.colorScheme.primaryContainer);
      expect(bubble.sentTextStyle!.color, theme.colorScheme.onPrimaryContainer);
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(
        input.decoration!.fillColor,
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(input.style!.color, theme.colorScheme.onSurface);
      expect(tester.takeException(), isNull);
    });
  }
}
