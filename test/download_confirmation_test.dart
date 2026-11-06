import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/home_page/widgets/model_management_panel.dart';

void main() {
  testWidgets('Missing or insufficient resources require explicit confirmation',
      (tester) async {
    for (final resources in <(double?, double?)>[
      (null, null),
      (null, 4),
      (2, null),
      (1, 4),
      (2, 3),
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelManagementPanel(
              key: UniqueKey(),
              availableStorageGb: resources.$1,
              availableRamGb: resources.$2,
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();
      expect(find.text('Czy na pewno chcesz pobrać?'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pobierz mimo to'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Sufficient resources start the preview without a warning',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ModelManagementPanel(
            availableStorageGb: 1.7,
            availableRamGb: 4,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Pobierz'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
