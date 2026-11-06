import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/statistics_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_line_chart.dart';

void main() {
  testWidgets('Shows historical charts, CPU temperature and selected samples', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: StatisticsPage(series: statisticsPreviewData)),
    );
    expect(find.byType(StatisticLineChart), findsNWidgets(7));
    expect(find.textContaining('Ostatnie 60 sekund'), findsOneWidget);
    expect(find.text('-60 s'), findsNWidgets(7));

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

    await tester.ensureVisible(find.text('Temperatura CPU'));
    await tester.pumpAndSettle();
    expect(find.text('Temperatura CPU').hitTestable(), findsOneWidget);
    expect(find.text('°C'), findsNWidgets(2));
    expect(find.text('Użycie GPU'), findsOneWidget);
    expect(find.text('Temperatura GPU'), findsOneWidget);
    for (final title in ['Użycie GPU', 'Temperatura GPU']) {
      final reading = tester.widget<Text>(
        find.byKey(ValueKey('chart-reading-$title')),
      );
      expect(reading.data, 'Brak danych');
    }
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1100, 844);
    await tester.pumpAndSettle();
    expect(find.byType(StatisticLineChart), findsNWidgets(7));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
