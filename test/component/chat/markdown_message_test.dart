import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/conversation_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/conversation_view.dart';

Iterable<({String text, TextStyle style})> _runs(
  InlineSpan span, [
  TextStyle inherited = const TextStyle(),
]) sync* {
  if (span is! TextSpan) return;
  final style = inherited.merge(span.style);
  if (span.text != null) yield (text: span.text!, style: style);
  for (final child in span.children ?? <InlineSpan>[]) {
    yield* _runs(child, style);
  }
}

List<({String text, TextStyle style})> _visibleRuns(WidgetTester tester) => [
  for (final text in tester.widgetList<RichText>(find.byType(RichText)))
    ..._runs(text.text),
];

Future<ConversationController> _open(
  WidgetTester tester,
  String text, {
  String author = ChatAuthors.assistant,
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final date = DateTime.utc(2026);
  final conversation = ConversationController(
    Conversation(id: 1, createdAt: date, updatedAt: date),
    messages: [
      ChatMessage(
        id: 'message',
        conversationId: 1,
        authorId: author,
        text: text,
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
  return conversation;
}

void main() {
  group('Assistant math formatting', () {
    for (final expression in [
      r'$\frac{h}{2}$',
      r'\(\frac{h}{2}\)',
      r'\[\frac{h}{2}\]',
      '\$\$\n\\frac{h}{2}\n\$\$',
      r'\frac{h}{2}',
      r'\frac{\sqrt{h}}{2}',
    ]) {
      testWidgets('Renders $expression as a mathematical expression', (
        tester,
      ) async {
        await _open(tester, 'Wynik: $expression.');
        expect(find.byType(Math), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Keeps LaTeX examples inside code literal', (tester) async {
      await _open(tester, '`\\frac{h}{2}`\n\n```latex\n\\frac{h}{2}\n```');
      expect(find.byType(Math), findsNothing);
      expect(
        _visibleRuns(tester).where((run) => run.text.contains(r'\frac{h}{2}')),
        hasLength(2),
      );
    });

    testWidgets('Malformed math falls back to readable source', (tester) async {
      await _open(tester, r'$\unknowncommand{h}$');
      expect(find.text(r'$\unknowncommand{h}$'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('A partial streamed expression does not hide following text', (
      tester,
    ) async {
      final conversation = await _open(tester, r'Wynik: \frac{h}{');
      expect(find.byType(Math), findsNothing);
      await conversation.updateMessage(
        'message',
        r'Wynik: \frac{h}{2}. Gotowe.',
      );
      await tester.pumpAndSettle();
      expect(find.byType(Math), findsOneWidget);
      expect(
        _visibleRuns(tester).any((run) => run.text.contains('Gotowe.')),
        isTrue,
      );
    });

    testWidgets(
      'Long equations fit a narrow screen without altering saved text',
      (tester) async {
        final source =
            r'$$' + List.filled(30, r'\frac{h}{2}').join('+') + r'$$';
        final conversation = await _open(tester, source, width: 320);
        expect(find.byType(Math), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(conversation.messages.single.text, source);
      },
    );

    testWidgets('Currency and escaped dollars remain ordinary text', (
      tester,
    ) async {
      await _open(tester, r'Cena: $5 albo $10. Koszt: \$20.');
      expect(find.byType(Math), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Assistant message Markdown', () {
    testWidgets('Renders double asterisks as bold text', (tester) async {
      await _open(tester, 'To jest **pogrubione**.');
      final bold = _visibleRuns(tester)
          .where((run) => run.text.contains('pogrubione'));
      expect(bold, isNotEmpty);
      expect(
        bold.every((run) => run.style.fontWeight == FontWeight.bold),
        isTrue,
      );
      expect(
        _visibleRuns(tester).any((run) => run.text.contains('**')),
        isFalse,
      );
    });

    testWidgets('Renders numbered list items without Markdown markers', (
      tester,
    ) async {
      await _open(tester, '1. **Spacer**\n2. Odpoczynek');
      expect(find.text('Spacer', findRichText: true), findsOneWidget);
      expect(find.text('Odpoczynek', findRichText: true), findsOneWidget);
      expect(
        _visibleRuns(tester).any((run) => run.text.contains('**')),
        isFalse,
      );
    });

    testWidgets('Renders code with a monospace style', (tester) async {
      await _open(tester, '```dart\nprint("Bielik");\n```');
      final code = _visibleRuns(tester)
          .where((run) => run.text.contains('print("Bielik");'));
      expect(code, isNotEmpty);
      expect(code.every((run) => run.style.fontFamily == 'monospace'), isTrue);
    });

    testWidgets('Re-renders formatting when streamed text is updated', (
      tester,
    ) async {
      final conversation = await _open(tester, '**W trakcie');
      await conversation.updateMessage('message', '**Gotowe**');
      await tester.pumpAndSettle();
      expect(find.text('Gotowe', findRichText: true), findsOneWidget);
      expect(
        _visibleRuns(tester).any((run) => run.text.contains('**')),
        isFalse,
      );
      expect(conversation.messages.single.text, '**Gotowe**');
    });

    testWidgets('Keeps user input as literal text', (tester) async {
      await _open(tester, '**doslownie**', author: ChatAuthors.user);
      expect(find.text('**doslownie**'), findsOneWidget);
    });

    testWidgets('Fits long code and tables on a narrow screen', (tester) async {
      await _open(
        tester,
        '## Przykład\n\n```\n${'long_identifier_' * 30}\n```\n\n'
        '| Model | Format |\n| --- | --- |\n| Bielik | Q8 |',
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays image alt text without fetching remote content', (
      tester,
    ) async {
      await _open(tester, '![Opis obrazu](https://example.invalid/image.png)');
      expect(find.text('Opis obrazu'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
