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

    testWidgets('Renders Fibonacci equations with subscripts in prose', (
      tester,
    ) async {
      await _open(
        tester,
        r'Ciąg Fibonacciego: \(F_n = F_{n-1} + F_{n-2}\), gdzie \(F_0 = 0\) i \(F_1 = 1\). Dla \(n = 20\): \(F_{20} = 6765\).',
      );
      expect(find.byType(Math), findsNWidgets(5));
      expect(
        _visibleRuns(
          tester,
        ).any((run) => run.text.contains(r'\(') || run.text.contains(r'F_{')),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders an unwrapped styled equation without swallowing prose', (
      tester,
    ) async {
      const source =
          r'Oto wzór dla ciągu Fibonacciego: \textbf{C}_n = C_{n-1} + C_{n-2}, gdzie \( C_0 = 42 \) i \( C_1 = 35. \)';
      final conversation = await _open(tester, source);
      expect(find.byType(Math), findsNWidgets(3));
      expect(
        _visibleRuns(tester).any(
          (run) => run.text.contains(r'\textbf') || run.text.contains(r'C_{'),
        ),
        isFalse,
      );
      expect(
        _visibleRuns(tester).any((run) => run.text.contains('gdzie')),
        isTrue,
      );
      expect(conversation.messages.single.text, source);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Keeps an unwrapped equation inside code literal', (
      tester,
    ) async {
      await _open(tester, r'`\textbf{C}_n = C_{n-1} + C_{n-2}`');
      expect(find.byType(Math), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Renders a complete align environment and preserves following prose',
      (tester) async {
        const source = r'''\begin{align*}
& \rho(\mathbf{x}) =  \int \vec E dV - , \
& \nabla \times \vec E = -, \
& \rho(\mathbf{x}) =  \int \vec D dV, \
& \nabla \times \vec B = \mu_0 \vec J + \mu_0 \vec E.
\end{align*}Gdzie:''';
        final conversation = await _open(tester, source, width: 320);
        expect(find.byType(Math), findsOneWidget);
        expect(
          _visibleRuns(tester).any(
            (run) => run.text.contains(r'\begin') || run.text.contains(r'\rho'),
          ),
          isFalse,
        );
        expect(
          _visibleRuns(tester).any((run) => run.text.contains('Gdzie:')),
          isTrue,
        );
        expect(conversation.messages.single.text, source);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Display equations put the following example on a new line', (
      tester,
    ) async {
      await _open(
        tester,
        r'Wzór: \[A = 4\pi r^2\]**Przykład:** Dla \(r = 5\).',
        width: 360,
      );
      final formula = find.byType(Math).first;
      final example = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Przykład:'),
      );
      expect(example, findsOneWidget);
      expect(
        tester.getTopLeft(example).dy,
        greaterThan(tester.getBottomLeft(formula).dy),
      );
      expect(tester.takeException(), isNull);
    });

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
