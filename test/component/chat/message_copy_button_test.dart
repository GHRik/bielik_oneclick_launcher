import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/conversation_view.dart';

Future<void> openCopyMessages(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
      ChatMessage(
        id: 'answer',
        conversationId: 1,
        authorId: ChatAuthors.assistant,
        text: 'Odpowiedź Bielika',
        createdAt: date,
      ),
    ],
    onDraftChanged: (_) {},
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    conversation.dispose();
  });
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
}

void main() {
  testWidgets('Shows a copy button below the user question', (tester) async {
    await openCopyMessages(tester);
    final button = find.byKey(const ValueKey('copy-message-question'));
    expect(button, findsOneWidget);
    expect(
      tester.getTopLeft(button).dy,
      greaterThan(tester.getBottomLeft(find.text('Moje pytanie')).dy),
    );
  });

  testWidgets('The question copy action fits a narrow screen', (tester) async {
    await openCopyMessages(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byKey(const ValueKey('copy-message-question'))).right,
      lessThanOrEqualTo(320),
    );
  });
}
