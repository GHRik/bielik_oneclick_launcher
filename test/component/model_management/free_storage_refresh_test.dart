import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_management_panel.dart';

import '../../support/in_memory_model_files_repository.dart';

class _PendingDownloadRepository extends InMemoryModelFilesRepository {
  @override
  Future<bool> hasPendingDownload(ModelFile model) async => true;
}

void main() {
  late InMemoryModelFilesRepository repository;
  late int refreshes;

  Future<void> openPanel(
    WidgetTester tester, {
    double storage = 10,
    InMemoryModelFilesRepository? files,
  }) async {
    repository = files ?? InMemoryModelFilesRepository();
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

  Future<void> startDownload(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Pobierz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pobierz'));
    await tester.pumpAndSettle();
  }

  group('Free storage during a download', () {
    testWidgets('Refreshes the reading while the download is running', (
      tester,
    ) async {
      await openPanel(tester);
      await startDownload(tester);
      expect(refreshes, 0);

      await tester.pump(ModelManagementPanel.resourcesRefreshInterval);
      expect(refreshes, 1);
      await tester.pump(ModelManagementPanel.resourcesRefreshInterval);
      expect(refreshes, 2);

      repository.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('Refreshes when the download completes and once more after '
        'storage settles, then stops', (tester) async {
      await openPanel(tester);
      await startDownload(tester);
      repository.finish();
      await tester.pumpAndSettle();
      expect(refreshes, 1);

      await tester.pump(ModelManagementPanel.resourcesSettleDelay);
      expect(refreshes, 2);
      await tester.pump(ModelManagementPanel.resourcesRefreshInterval * 3);
      expect(refreshes, 2);
    });

    testWidgets('Refreshes when the download is cancelled and once more after '
        'storage settles', (tester) async {
      await openPanel(tester);
      await startDownload(tester);
      await tester.ensureVisible(find.text('Anuluj pobieranie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anuluj pobieranie'));
      await tester.pumpAndSettle();
      expect(refreshes, 1);

      await tester.pump(ModelManagementPanel.resourcesSettleDelay);
      expect(refreshes, 2);
    });

    testWidgets('Follows a download resumed when the model is selected', (
      tester,
    ) async {
      await openPanel(tester, files: _PendingDownloadRepository());
      expect(find.text('Anuluj pobieranie'), findsOneWidget);

      await tester.pump(ModelManagementPanel.resourcesRefreshInterval);
      expect(refreshes, 1);
      repository.finish();
      await tester.pumpAndSettle();
      expect(refreshes, 2);
    });

    testWidgets('Counts only the part that is still to be downloaded', (
      tester,
    ) async {
      await openPanel(tester);
      await startDownload(tester);
      repository.report(
        const ModelDownloadProgress(
          receivedBytes: 850000000,
          totalBytes: 1700000000,
          bytesPerSecond: 0,
        ),
      );
      await tester.pump();
      expect(
        find.text('Wymagane: 0,85 GB · Wolne miejsce: 10,00 GB'),
        findsOneWidget,
      );

      repository.finish();
      await tester.pumpAndSettle();
    });

    testWidgets('Deleting a model refreshes once, without the timer', (
      tester,
    ) async {
      final files = InMemoryModelFilesRepository()
        ..downloaded.add(bielikModels.first.file!.name);
      await openPanel(tester, files: files);
      await tester.ensureVisible(find.byTooltip('Opcje modelu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opcje modelu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(refreshes, 1);

      await tester.pump(ModelManagementPanel.resourcesRefreshInterval * 3);
      expect(refreshes, 1);
    });

    testWidgets('Stops refreshing after the panel is removed', (tester) async {
      await openPanel(tester);
      await startDownload(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(ModelManagementPanel.resourcesRefreshInterval * 2);
      expect(refreshes, 0);
      repository.finish();
    });
  });
}
