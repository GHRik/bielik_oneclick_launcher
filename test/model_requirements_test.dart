import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_requirements_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/requirement_status_row.dart';

import 'support/in_memory_model_files_repository.dart';

void main() {
  testWidgets(
    'Resource information wraps on narrow screens with enlarged text',
    (tester) async {
      for (final width in [280.0, 320.0, 600.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: ModelRequirementsCard(
                        model: bielikModels.last,
                        availableStorageGb: 123.45,
                        availableRamGb: 4.25,
                        totalRamGb: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final label in [
          'Wolne miejsce u Ciebie: 123,45 GB',
          'Dostępny RAM u Ciebie: 4,25 GB',
        ]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.size.width, lessThan(width - 40));
        }
      }
    },
  );

  testWidgets(
    'Marks missing, insufficient and sufficient resources independently',
    (tester) async {
      for (final values in <(double?, double?, int, int)>[
        (null, null, 0, 0),
        (0, 0, 2, 0),
        (1.7, 4, 0, 2),
        (1, 4, 1, 1),
        (2, 3, 1, 1),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ModelRequirementsCard(
                model: bielikModels.first,
                availableStorageGb: values.$1,
                availableRamGb: values.$2,
              ),
            ),
          ),
        );
        expect(find.text('Za mało'), findsNWidgets(values.$3));
        expect(find.text('Wystarczająco'), findsNWidgets(values.$4));
        expect(
          find.text('Brak danych'),
          findsNWidgets(2 - values.$3 - values.$4),
        );
        final boxes = tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(RequirementStatusRow),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect(
          boxes
              .where(
                (box) =>
                    (box.decoration as BoxDecoration).color ==
                    Colors.red.shade50,
              )
              .length,
          values.$3,
        );
        expect(
          boxes
              .where(
                (box) =>
                    (box.decoration as BoxDecoration).color ==
                    Colors.green.shade50,
              )
              .length,
          values.$4,
        );
      }
    },
  );

  testWidgets('Rechecks resource colors when selecting a larger model', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelManagementPanel(
              models: bielikModels,
              repository: InMemoryModelFilesRepository(),
              availableStorageGb: 4,
              availableRamGb: 6,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
