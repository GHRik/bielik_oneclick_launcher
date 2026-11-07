import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';

import 'support/in_memory_chat_repository.dart';
import 'support/in_memory_model_files_repository.dart';

Future<void> _openChat(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MyApp(
      modelFilesRepository: InMemoryModelFilesRepository(),
      chatRepository: InMemoryChatRepository(),
      statisticsRepository: LocalStatisticsRepository(
        const StatisticsDataSource(),
        GenerationMetrics(),
      ),
    ),
  );
  await tester.tap(find.text('Otwórz czat'));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

Future<void> _openSidebar(WidgetTester tester) async {
  final menu = find.byTooltip('Rozmowy');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await tester.pumpAndSettle();
  }
}

Future<void> _newChat(WidgetTester tester) async {
  await _openSidebar(tester);
  await tester.tap(find.text('New chat'));
  await tester.pumpAndSettle();
}

Future<void> _selectChat(WidgetTester tester, String title) async {
  await _openSidebar(tester);
  await tester.tap(find.widgetWithText(ListTile, title));
  await tester.pumpAndSettle();
}

Future<void> _requestDelete(WidgetTester tester, String title) async {
  await _openSidebar(tester);
  await tester.tap(find.byTooltip('Usuń rozmowę: $title'));
  await tester.pumpAndSettle();
}

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
  await tester.pumpAndSettle();
}

String _draft(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('Conversation navigation', () {
    testWidgets('New chat opens an empty conversation with an empty draft', (
      tester,
    ) async {
      await _openChat(tester);
      await _send(tester, 'First conversation');

      await _newChat(tester);

      expect(find.text('First conversation'), findsNothing);
      expect(find.text('W czym mogę pomóc?'), findsOneWidget);
      expect(_draft(tester), '');
    });

    testWidgets('Selecting a conversation shows only its messages', (
      tester,
    ) async {
      await _openChat(tester);
      await _send(tester, 'First conversation');
      await _newChat(tester);
      await _send(tester, 'Second conversation');

      await _selectChat(tester, 'First conversation');

      expect(find.text('First conversation'), findsOneWidget);
      expect(find.text('Second conversation'), findsNothing);
    });

    testWidgets('Switching conversations restores each draft', (tester) async {
      await _openChat(tester);
      await _send(tester, 'First conversation');
      await _newChat(tester);
      await _send(tester, 'Second conversation');
      await tester.enterText(find.byType(TextField), 'Second draft');
      await _selectChat(tester, 'First conversation');
      expect(_draft(tester), '');

      await _selectChat(tester, 'Second conversation');

      expect(_draft(tester), 'Second draft');
    });

    testWidgets('Statistics opens from the chat toolbar', (tester) async {
      await _openChat(tester);

      await tester.tap(find.byTooltip('Statystyki'));
      await tester.pumpAndSettle();

      expect(find.text('Statystyki'), findsOneWidget);
      expect(find.text('Wydajność modelu'), findsOneWidget);
      expect(find.text('Prędkość generowania'), findsOneWidget);
      expect(find.text('RAM aplikacji'), findsOneWidget);
    });

    testWidgets('Returning from statistics preserves the current draft', (
      tester,
    ) async {
      await _openChat(tester);
      await tester.enterText(find.byType(TextField), 'Draft');
      await tester.tap(find.byTooltip('Statystyki'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(_draft(tester), 'Draft');
    });

    testWidgets(
      'Resizing exposes a permanent sidebar and preserves the draft',
      (tester) async {
        await _openChat(tester);
        await _send(tester, 'First conversation');
        await _newChat(tester);
        await tester.enterText(find.byType(TextField), 'Draft');

        tester.view.physicalSize = const Size(1100, 844);
        await tester.pumpAndSettle();

        expect(find.text('New chat').hitTestable(), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(find.byTooltip('Rozmowy'), findsNothing);
        expect(_draft(tester), 'Draft');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Returning from home preserves the selected conversation', (
      tester,
    ) async {
      await _openChat(tester);
      await _send(tester, 'First conversation');
      await _newChat(tester);
      await _send(tester, 'Second conversation');
      await tester.enterText(find.byType(TextField), 'Draft');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otwórz czat'));
      await tester.pumpAndSettle();

      expect(find.text('Second conversation'), findsOneWidget);
      expect(_draft(tester), 'Draft');
    });
  });

  group('Conversation deletion confirmation', () {
    testWidgets('Requests confirmation before deleting a conversation', (
      tester,
    ) async {
      await _openChat(tester, width: 1100);
      await _send(tester, 'First conversation');

      await _requestDelete(tester, 'First conversation');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('Cancelling deletion keeps the conversation', (tester) async {
      await _openChat(tester, width: 1100);
      await _send(tester, 'First conversation');
      await _requestDelete(tester, 'First conversation');

      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.widgetWithText(ListTile, 'First conversation'),
        findsOneWidget,
      );
    });

    testWidgets('Confirmed deletion removes an inactive conversation', (
      tester,
    ) async {
      await _openChat(tester, width: 1100);
      await _send(tester, 'First conversation');
      await _newChat(tester);

      await _requestDelete(tester, 'First conversation');
      await _confirmDelete(tester);

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('First conversation'), findsNothing);
      expect(find.text('W czym mogę pomóc?'), findsOneWidget);
    });

    testWidgets('Deleting the active chat selects the remaining conversation', (
      tester,
    ) async {
      await _openChat(tester, width: 1100);
      await _send(tester, 'First conversation');
      await tester.enterText(find.byType(TextField), 'Saved draft');
      await _newChat(tester);

      await _requestDelete(tester, 'Nowa rozmowa');
      await _confirmDelete(tester);

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('First conversation'), findsNWidgets(2));
      expect(_draft(tester), 'Saved draft');
    });

    testWidgets('Deleting the last chat creates an empty replacement', (
      tester,
    ) async {
      await _openChat(tester, width: 1100);
      await _send(tester, 'Only conversation');

      await _requestDelete(tester, 'Only conversation');
      await _confirmDelete(tester);

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Only conversation'), findsNothing);
      expect(find.text('W czym mogę pomóc?'), findsOneWidget);
      expect(_draft(tester), '');
      expect(tester.takeException(), isNull);
    });
  });
}
