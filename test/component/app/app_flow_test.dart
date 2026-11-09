import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

Future<void> _openHome(
  WidgetTester tester, {
  Size size = const Size(360, 640),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MyApp(
      modelFilesRepository: InMemoryModelFilesRepository(),
      chatRepository: InMemoryChatRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _startDownload(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Pobierz'));
  await tester.tap(find.text('Pobierz'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pobierz mimo to'));
  await tester.pumpAndSettle();
}

Future<void> _selectLargerModel(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(DropdownButtonFormField<BielikModel>));
  await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bielik 4.5B v3.0 · Q8').last);
  await tester.pumpAndSettle();
}

void main() {
  group('Home model management', () {
    testWidgets('Displays requirements for the initially selected model', (
      tester,
    ) async {
      await _openHome(tester);

      expect(find.text('Miejsce na model'), findsOneWidget);
      expect(find.text('1,70 GB / —'), findsOneWidget);
    });

    testWidgets('Shows percentage, speed and ETA for an active download', (
      tester,
    ) async {
      await _openHome(tester);

      await _startDownload(tester);

      expect(find.text('Pobieranie · 0%'), findsOneWidget);
      expect(find.text('Prędkość: 0,0 MB/s'), findsOneWidget);
      expect(find.text('Pozostało (ETA): Obliczanie…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'Cancelling a download removes progress and keeps deletion hidden',
      (tester) async {
        await _openHome(tester);
        await _startDownload(tester);

        await tester.ensureVisible(find.text('Anuluj pobieranie'));
        await tester.tap(find.text('Anuluj pobieranie'));
        await tester.pumpAndSettle();

        expect(find.text('Anuluj pobieranie'), findsNothing);
        expect(find.text('Usuń'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Updates requirements when selecting the larger model', (
      tester,
    ) async {
      await _openHome(tester);

      await _selectLargerModel(tester);

      expect(find.text('5,06 GB / —'), findsOneWidget);
      expect(find.text('8,00 GB / —'), findsOneWidget);
    });

    testWidgets(
      'Keeps the open-chat button near the bottom on a small screen',
      (tester) async {
        await _openHome(tester);
        await _selectLargerModel(tester);

        expect(
          tester.getBottomLeft(find.text('Otwórz czat')).dy,
          greaterThan(550),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Keeps the open-chat button accessible in landscape', (
      tester,
    ) async {
      await _openHome(tester);
      await _selectLargerModel(tester);

      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();

      expect(find.text('Otwórz czat').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Customize model opens the existing settings screen', (
    tester,
  ) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('Dostosuj model'));
    await tester.tap(find.text('Dostosuj model'));
    await tester.pumpAndSettle();

    expect(find.text('Konfiguracja LLM'), findsOneWidget);
    expect(find.text('Zapisz'), findsOneWidget);
  });

  group('Chat entry from home', () {
    Future<void> openChat(WidgetTester tester) async {
      await _openHome(tester, size: const Size(800, 600));
      await tester.tap(find.text('Otwórz czat'));
      await tester.pumpAndSettle();
    }

    Future<void> send(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'Cześć Bielik!');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    }

    testWidgets('Shows the selected model with its initial CPU status', (
      tester,
    ) async {
      await openChat(tester);

      expect(find.text('Bielik 1.5B v3.0 · Q8'), findsOneWidget);
      expect(find.text('CPU · niezaładowany'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Sending a message displays it and clears the input', (
      tester,
    ) async {
      await openChat(tester);

      await send(tester);

      expect(find.text('Cześć Bielik!'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('Returning from home preserves the sent message', (
      tester,
    ) async {
      await openChat(tester);
      await send(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otwórz czat'));
      await tester.pumpAndSettle();

      expect(find.text('Cześć Bielik!'), findsOneWidget);
    });
  });
}
