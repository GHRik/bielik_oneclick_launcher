import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/home_page/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/home_page/widgets/model_management_panel.dart';
import 'package:bielik_oneclick_launcher/home_page/widgets/model_requirements_card.dart';

void main() {
  testWidgets('Marks missing, insufficient and sufficient resources independently',
      (tester) async {
    for (final values in <(double?, double?, int, int)>[
      (null, null, 0, 0),
      (0, 0, 2, 0),
      (1.7, 4, 0, 2),
      (1, 4, 1, 1),
      (2, 3, 1, 1),
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModelRequirementsCard(
            model: bielikModels.first,
            availableStorageGb: values.$1,
            availableRamGb: values.$2,
          ),
        ),
      ));
      expect(find.text('Za mało'), findsNWidgets(values.$3));
      expect(find.text('Wystarczająco'), findsNWidgets(values.$4));
      expect(find.text('Brak danych'), findsNWidgets(2 - values.$3 - values.$4));
      final chips = tester.widgetList<Chip>(find.byType(Chip));
      expect(
        chips.where((chip) => chip.backgroundColor == Colors.red.shade50).length,
        values.$3,
      );
      expect(
        chips.where((chip) => chip.backgroundColor == Colors.green.shade50).length,
        values.$4,
      );
    }
  });

  testWidgets('Rechecks resource colors when selecting a larger model',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ModelManagementPanel(
            availableStorageGb: 4,
            availableRamGb: 6,
          ),
        ),
      ),
    ));
    expect(find.text('Wystarczająco'), findsNWidgets(2));
    await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bielik 4.5B v3.0 · Q8').last);
    await tester.pumpAndSettle();
    expect(find.text('Za mało'), findsNWidgets(2));
    expect(find.text('Wystarczająco'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
