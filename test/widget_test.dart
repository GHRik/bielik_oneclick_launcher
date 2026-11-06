import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/main.dart';
import 'package:bielik_oneclick_launcher/bielik_models.dart';

void main() {
  testWidgets('Selects a model and keeps chat below requirements on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Miejsce na dysku: około 1,7 GB'), findsOneWidget);
    await tester.tap(find.text('Pobierz'));
    await tester.pumpAndSettle();
    expect(find.text('Pobieranie modeli będzie dostępne wkrótce.'), findsOneWidget);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(find.text('Usuwanie modeli będzie dostępne wkrótce.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<BielikModel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bielik 4.5B v3.0 · Q8').last);
    await tester.pumpAndSettle();
    expect(find.text('Miejsce na dysku: około 5,06 GB'), findsOneWidget);
    expect(find.textContaining('12 GB RAM'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Otwórz czat')).dy, greaterThan(550));
    expect(tester.takeException(), isNull);

    ScaffoldMessenger.of(tester.element(find.text('Usuń')))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(640, 360);
    await tester.pumpAndSettle();
    expect(find.text('Otwórz czat').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
