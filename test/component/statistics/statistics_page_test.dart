import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/statistics_page.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_line_chart.dart';

Future<void> _showStatistics(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: StatisticsPage(series: statisticsPreviewData)),
  );
}

void main() {
  group('Statistics page preview', () {
    testWidgets('Missing latest samples do not display stale readings', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatisticCard(
              series: StatisticSeries(
                title: 'Użycie GPU',
                unit: '%',
                minimum: 0,
                maximum: 100,
                values: [42, null],
              ),
            ),
          ),
        ),
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.text('42'), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('Glass cards fit enlarged text in ${brightness.name} mode', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const StatisticsPage(series: statisticsPreviewData),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(StatisticLineChart), findsNWidgets(5));
      });
    }

    testWidgets('Displays charts with a 60-second history axis', (
      tester,
    ) async {
      await _showStatistics(tester);

      expect(find.byType(StatisticLineChart), findsNWidgets(5));
      expect(find.textContaining('Ostatnie 60 sekund'), findsOneWidget);
      expect(find.text('-60 s'), findsNWidgets(5));
    });

    testWidgets('Displays the sample selected by tapping a chart', (
      tester,
    ) async {
      await _showStatistics(tester);
      final graph = find.descendant(
        of: find.byType(StatisticLineChart).first,
        matching: find.byType(GestureDetector),
      );

      await tester.tap(graph);
      await tester.pump();

      final reading = tester.widget<Text>(
        find.byKey(const ValueKey('chart-reading-Prędkość generowania')),
      );
      expect(reading.data, '-30 s · 19 tok./s');
    });

    testWidgets('Displays CPU temperature with Celsius units', (tester) async {
      await _showStatistics(tester);

      await tester.ensureVisible(find.text('Temperatura CPU'));
      await tester.pumpAndSettle();

      expect(find.text('Temperatura CPU').hitTestable(), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Keeps every chart after resizing to a desktop window', (
      tester,
    ) async {
      await _showStatistics(tester);

      tester.view.physicalSize = const Size(1100, 844);
      await tester.pumpAndSettle();

      expect(find.byType(StatisticLineChart), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}
