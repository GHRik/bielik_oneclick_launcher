import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/app.dart';

void main() {
  testWidgets('Creates separate chats and preserves messages and drafts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pierwsza rozmowa');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rozmowy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();
    expect(find.text('Pierwsza rozmowa'), findsNothing);
    expect(find.text('W czym mogę pomóc?'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');

    await tester.enterText(find.byType(TextField), 'Druga rozmowa');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Szkic drugiej rozmowy');

    await tester.tap(find.byTooltip('Rozmowy'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ListTile, 'Pierwsza rozmowa'));
    await tester.pumpAndSettle();
    expect(find.text('Pierwsza rozmowa'), findsOneWidget);
    expect(find.text('Druga rozmowa'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');

    await tester.tap(find.byTooltip('Rozmowy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Druga rozmowa'));
    await tester.pumpAndSettle();
    expect(find.text('Druga rozmowa'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Szkic drugiej rozmowy');

    tester.view.physicalSize = const Size(1100, 844);
    await tester.pumpAndSettle();
    expect(find.text('New chat').hitTestable(), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byTooltip('Rozmowy'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Szkic drugiej rozmowy');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Szkic drugiej rozmowy');

    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('W czym mogę pomóc?'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    await tester.tap(find.byTooltip('Usuń rozmowę: Pierwsza rozmowa'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));

    await tester.tap(find.byTooltip('Usuń rozmowę: Pierwsza rozmowa'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Pierwsza rozmowa'), findsNothing);
    expect(find.text('W czym mogę pomóc?'), findsOneWidget);

    await tester.tap(find.byTooltip('Usuń rozmowę: Nowa rozmowa'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Druga rozmowa'), findsNWidgets(2));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Szkic drugiej rozmowy');

    await tester.tap(find.byTooltip('Usuń rozmowę: Druga rozmowa'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Druga rozmowa'), findsNothing);
    expect(find.text('W czym mogę pomóc?'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
