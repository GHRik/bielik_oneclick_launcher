import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';

import '../support/in_memory_model_files_repository.dart';

Future<void> _openPanel(
  WidgetTester tester,
  double? storage,
  double? ram,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ModelManagementPanel(
            models: bielikModels,
            repository: InMemoryModelFilesRepository(),
            key: UniqueKey(),
            availableStorageGb: storage,
            availableRamGb: ram,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('Download safety confirmation', () {
    final cases = <String, (double?, double?)>{
      'both resource readings are missing': (null, null),
      'storage is unknown': (null, 4),
      'RAM is unknown': (2, null),
      'storage is insufficient': (1, 4),
      'RAM is insufficient': (2, 3),
    };
    for (final entry in cases.entries) {
      testWidgets('Shows a warning when ${entry.key}', (tester) async {
        await _openPanel(tester, entry.value.$1, entry.value.$2);

        await tester.tap(find.text('Pobierz'));
        await tester.pumpAndSettle();

        expect(find.text('Czy na pewno chcesz pobrać?'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });
    }

    testWidgets('Cancelling leaves the download stopped', (tester) async {
      await _openPanel(tester, null, null);
      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Confirming starts a download despite missing resources', (
      tester,
    ) async {
      await _openPanel(tester, null, null);
      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pobierz mimo to'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Sufficient resources start downloading without a warning', (
      tester,
    ) async {
      await _openPanel(tester, 1.7, 4);

      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
