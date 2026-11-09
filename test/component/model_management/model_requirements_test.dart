import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_requirements_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/requirement_status_row.dart';

import '../../support/in_memory_model_files_repository.dart';

Finder _bar(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is RequirementStatusRow && widget.requirement == label,
  ),
  matching: find.byType(LinearProgressIndicator),
);

Future<void> _card(WidgetTester tester, {double? ram, double? storage}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelRequirementsCard(
            model: bielikModels.first,
            availableRamGb: ram,
            availableStorageGb: storage,
          ),
        ),
      ),
    );

void main() {
  group('Resource bars', () {
    testWidgets('Sufficient RAM fills only the required proportion in green', (
      tester,
    ) async {
      await _card(tester, ram: 8, storage: 10);
      final bar = tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM'));
      expect(bar.value, 0.5);
      expect(bar.color, Colors.green.shade700);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('Insufficient RAM fills the entire bar in red', (tester) async {
      await _card(tester, ram: 2, storage: 10);
      final bar = tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM'));
      expect(bar.value, 1);
      expect(bar.color, Colors.red.shade700);
    });

    testWidgets('Unknown RAM shows an empty neutral bar', (tester) async {
      await _card(tester, storage: 10);
      final bar = tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM'));
      expect(bar.value, 0);
      expect(bar.semanticsLabel, contains('Brak danych'));
    });

    testWidgets('Storage status is independent of RAM status', (tester) async {
      await _card(tester, ram: 2, storage: 10);
      final bar = tester.widget<LinearProgressIndicator>(
        _bar('Miejsce na model'),
      );
      expect(bar.value, lessThan(1));
      expect(bar.color, Colors.green.shade700);
    });

    testWidgets('Zero available resources render without invalid percentages', (
      tester,
    ) async {
      await _card(tester, ram: 0, storage: 0);
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM')).value,
        1,
      );
    });

    for (final width in [280.0, 320.0, 600.0]) {
      testWidgets('Resource bars fit enlarged text at ${width}px', (
        tester,
      ) async {
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('Selecting another model updates the resource bars', (
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
    expect(
      tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM')).value,
      closeTo(4 / 6, 0.001),
    );
    await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(bielikModels.last.name).last);
    await tester.pumpAndSettle();
    expect(tester.widget<LinearProgressIndicator>(_bar('Pamięć RAM')).value, 1);
  });

  testWidgets('Downloaded models hide resource bars', (tester) async {
    final repository = InMemoryModelFilesRepository()
      ..downloaded.add(bielikModels.first.file!.name);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelManagementPanel(
              models: bielikModels,
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ModelRequirementsCard), findsNothing);
    expect(find.text('Pobrano'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(bielikModels.last.name).last);
    await tester.pumpAndSettle();
    expect(find.byType(ModelRequirementsCard), findsOneWidget);
  });
}
