import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';

import '../../support/in_memory_model_files_repository.dart';

void main() {
  late InMemoryModelFilesRepository repository;
  late int refreshes;

  Future<void> openPanel(
    WidgetTester tester, {
    int savedBytes = 0,
    double storage = 10,
  }) async {
    repository = InMemoryModelFilesRepository()..savedBytes = savedBytes;
    refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelManagementPanel(
              models: bielikModels,
              repository: repository,
              availableStorageGb: storage,
              availableRamGb: 8,
              onResourcesChanged: () async => refreshes++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  const notice =
      'Pobrano już 400,0 MB z 1,7 GB.\n'
      '„Pobierz” dokończy pobieranie od tego miejsca.';

  group('Part saved from an interrupted download', () {
    testWidgets('Shows how much is saved and that the download continues', (
      tester,
    ) async {
      await openPanel(tester, savedBytes: 400000000);

      expect(find.text(notice), findsOneWidget);
      expect(find.text('Usuń pobraną część'), findsOneWidget);
    });

    testWidgets('Shows nothing when no part is saved', (tester) async {
      await openPanel(tester);

      expect(find.text('Usuń pobraną część'), findsNothing);
    });

    testWidgets('Hides the notice while the download runs', (tester) async {
      await openPanel(tester, savedBytes: 400000000);
      await tap(tester, 'Pobierz');

      expect(find.text('Anuluj pobieranie'), findsOneWidget);
      expect(find.text(notice), findsNothing);
      repository.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('Removes the saved part on request and refreshes storage', (
      tester,
    ) async {
      await openPanel(tester, savedBytes: 400000000);
      await tap(tester, 'Usuń pobraną część');

      expect(repository.savedBytes, 0);
      expect(find.text(notice), findsNothing);
      expect(refreshes, greaterThanOrEqualTo(1));
    });

    testWidgets('Counts the saved part towards the space the model needs', (
      tester,
    ) async {
      // 1,7 GB model with 0,6 GB saved: 1,2 GB free is enough for the rest.
      await openPanel(tester, savedBytes: 600000000, storage: 1.2);
      await tap(tester, 'Pobierz');

      expect(find.text('Za mało miejsca'), findsNothing);
      expect(find.text('Anuluj pobieranie'), findsOneWidget);
      repository.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('The requirements card agrees with the download check', (
      tester,
    ) async {
      await openPanel(tester, savedBytes: 600000000, storage: 1.2);

      expect(find.textContaining('Brakuje'), findsNothing);
      expect(
        find.text('Wymagane: 1,70 GB · Wolne miejsce: 1,80 GB'),
        findsOneWidget,
      );
    });

    testWidgets('Still blocks a download that cannot fit', (tester) async {
      await openPanel(tester, savedBytes: 600000000, storage: 1);
      await tap(tester, 'Pobierz');

      expect(find.text('Za mało miejsca'), findsOneWidget);
    });
  });
}
