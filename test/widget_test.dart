import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/main.dart';

void main() {
  testWidgets('Opens chat, sends a message and preserves it after returning',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();

    expect(find.text('Czat'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cześć Bielik!');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Cześć Bielik!'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();

    expect(find.text('Cześć Bielik!'), findsOneWidget);
  });
}
