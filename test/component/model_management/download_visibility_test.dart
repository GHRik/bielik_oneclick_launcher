import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_download_progress.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_selection_card.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _FailingDownloadRepository extends InMemoryModelFilesRepository {
  @override
  Future<void> download(
    ModelFile model,
    void Function(ModelDownloadProgress) onProgress,
  ) async => throw StateError('Pobieranie zostało przerwane.');
}

class _PendingDownloadRepository extends InMemoryModelFilesRepository {
  @override
  Future<bool> hasPendingDownload(ModelFile model) async => true;
}

void main() {
  // The phone from the report: 1080 x 2400 px at 2.625 px per logical pixel.
  Future<void> openHome(
    WidgetTester tester, {
    InMemoryModelFilesRepository? files,
    Size size = const Size(411, 914),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MyApp(
        modelFilesRepository: files ?? InMemoryModelFilesRepository(),
        chatRepository: InMemoryChatRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

  double listBottom(WidgetTester tester) =>
      tester.getRect(find.byType(SingleChildScrollView)).bottom;

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 900));
    await tester.pumpAndSettle();
  }

  group('Download controls stay in view', () {
    testWidgets('Shows the whole progress card when a download starts', (
      tester,
    ) async {
      await openHome(tester);
      await tester.ensureVisible(find.text('Pobierz'));
      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pobierz mimo to'));
      await tester.pumpAndSettle();

      expect(find.text('Pobieranie · 0%').hitTestable(), findsOneWidget);
      expect(find.text('Anuluj pobieranie').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.text('Anuluj pobieranie')).bottom,
        lessThanOrEqualTo(listBottom(tester)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Shows the progress card of a download resumed on start', (
      tester,
    ) async {
      await openHome(tester, files: _PendingDownloadRepository());

      expect(find.text('Anuluj pobieranie').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Shows the download button after selecting another model', (
      tester,
    ) async {
      await openHome(tester);
      await scrollToTop(tester);
      await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bielik 4.5B v3.0 · Q8').last);
      await tester.pumpAndSettle();

      expect(find.text('Pobierz').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.widgetWithText(FilledButton, 'Pobierz')).bottom,
        lessThanOrEqualTo(listBottom(tester)),
      );
    });

    testWidgets('Shows the download button when the model is not downloaded', (
      tester,
    ) async {
      await openHome(tester);

      expect(find.text('Pobierz').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.widgetWithText(FilledButton, 'Pobierz')).bottom,
        lessThanOrEqualTo(listBottom(tester)),
      );
    });

    testWidgets('Never scrolls the model selection off a short screen', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.resetPadding);
      await openHome(tester, size: const Size(360, 640));

      final selection = find.byType(DropdownButtonFormField<BielikModel>);
      expect(selection.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.byType(ModelSelectionCard)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(SingleChildScrollView)).top - 0.5,
        ),
      );
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        greaterThan(0),
      );
    });

    testWidgets('Shows the download button again after deleting the model', (
      tester,
    ) async {
      final files = InMemoryModelFilesRepository()
        ..downloaded.add(bielikModels.first.file!.name);
      await openHome(tester, files: files);
      await tester.tap(find.byTooltip('Opcje modelu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();

      expect(find.text('Pobierz').hitTestable(), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<BielikModel>).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('Does not scroll when the model is already downloaded', (
      tester,
    ) async {
      final files = InMemoryModelFilesRepository()
        ..downloaded.add(bielikModels.first.file!.name);
      await openHome(tester, files: files);

      expect(find.textContaining('Wszystko gotowe.'), findsOneWidget);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        0,
      );
    });

    testWidgets('Shows the error and the retry button after a failure', (
      tester,
    ) async {
      await openHome(tester, files: _FailingDownloadRepository());
      await tester.ensureVisible(find.text('Pobierz'));
      await tester.tap(find.text('Pobierz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pobierz mimo to'));
      await tester.pumpAndSettle();

      expect(find.text('Sprawdź ponownie').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.text('Sprawdź ponownie')).bottom,
        lessThanOrEqualTo(listBottom(tester)),
      );
    });
  });
}
