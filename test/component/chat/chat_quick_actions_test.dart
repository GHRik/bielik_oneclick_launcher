import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_quick_actions.dart';

void main() {
  testWidgets('Quick actions fit a narrow screen with enlarged text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SizedBox(width: 280, child: ChatQuickActions()),
          ),
        ),
      ),
    );
    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final label in ['Przetłumacz', 'Streść', 'Analizuj']) {
    testWidgets('The $label chip invokes only its own action', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatQuickActions(
              onTranslate: () => calls.add('Przetłumacz'),
              onSummarize: () => calls.add('Streść'),
              onAnalyze: () => calls.add('Analizuj'),
            ),
          ),
        ),
      );
      await tester.tap(find.text(label));
      expect(calls, [label]);
    });
  }
}
