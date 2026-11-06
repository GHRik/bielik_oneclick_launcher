import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/statistics_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/statistics_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_line_chart.dart';

class FakeStatisticsSource extends StatisticsDataSource {
  Map<String, dynamic> values = {};
  int reads = 0;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> read() async {
    reads++;
    if (fail) throw StateError('unavailable');
    return values;
  }
}

void main() {
  testWidgets('GPU readings travel through the adapter into one chart each', (
    tester,
  ) async {
    final source = FakeStatisticsSource()
      ..values = {'gpuUsagePercent': 37.5, 'gpuTemperature': 56.25};
    final repository = LocalStatisticsRepository(source, GenerationMetrics());
    final controller = StatisticsController(repository);
    await controller.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(series: const [], controller: controller),
      ),
    );
    expect(find.byType(StatisticLineChart), findsNWidgets(9));
    for (final title in ['Użycie GPU', 'Temperatura GPU']) {
      expect(find.text(title), findsOneWidget);
    }
    final gpu = find
        .byType(StatisticLineChart)
        .evaluate()
        .map((element) => element.widget as StatisticLineChart)
        .singleWhere((widget) => widget.series.title == 'Użycie GPU');
    expect(gpu.series.values, [37.5]);
    expect(
      controller.series.singleWhere((s) => s.title == 'Temperatura GPU').values,
      [56.25],
    );
    source.values = {'gpuUsagePercent': 0, 'gpuTemperature': 0};
    await controller.refresh();
    await tester.pump();
    expect(
      controller.series.singleWhere((s) => s.title == 'Użycie GPU').values.last,
      0,
    );
    source.values = {'gpuUsagePercent': 101, 'gpuTemperature': double.nan};
    await controller.refresh();
    await tester.pump();
    expect(
      controller.series.singleWhere((s) => s.title == 'Użycie GPU').values.last,
      isNull,
    );
    expect(
      controller.series
          .singleWhere((s) => s.title == 'Temperatura GPU')
          .values
          .last,
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test(
    'Uses measured values, engine token counts and actual sample times',
    () async {
      var now = DateTime(2026);
      final source = FakeStatisticsSource()
        ..values = {
          'appRamBytes': 2500000000,
          'batteryTemperature': 36.5,
          'appCpuPercent': 25,
        };
      final metrics = GenerationMetrics();
      final repository = LocalStatisticsRepository(
        source,
        metrics,
        now: () => now,
      );
      var series = await repository.sample();
      expect(series[0].values, [null]);
      expect(series[2].values, [2.5]);
      expect(series[4].values, [null]);
      expect(series[5].values, [36.5]);
      metrics.complete(tokens: 100, duration: const Duration(seconds: 10));
      now = now.add(const Duration(seconds: 4));
      series = await repository.sample();
      expect(series[0].values, [null, 10]);
      expect(series[3].values, [null, 100]);
      expect(series[0].secondsAgo, [-4, 0]);
      metrics.complete(tokens: 50, duration: const Duration(seconds: 5));
      now = now.add(const Duration(seconds: 61));
      series = await repository.sample();
      expect(series[3].values, [150]);
      expect(series[0].secondsAgo, [0]);
    },
  );

  test(
    'Missing native measurements leave gaps rather than artificial zeroes',
    () async {
      final source = FakeStatisticsSource()
        ..values = {'appCpuPercent': 0, 'appRamBytes': double.nan};
      final repository = LocalStatisticsRepository(source, GenerationMetrics());
      var series = await repository.sample();
      expect(series[6].values.last, 0);
      expect(series[2].values.last, isNull);
      source.fail = true;
      series = await repository.sample();
      expect(series[6].values.last, isNull);
      expect(series[4].values.every((value) => value == null), isTrue);
    },
  );

  testWidgets(
    'Samples during foreground operation and stops when paused or disposed',
    (tester) async {
      final source = FakeStatisticsSource();
      final controller = StatisticsController(
        LocalStatisticsRepository(source, GenerationMetrics()),
      );
      controller.start();
      await tester.pump();
      expect(source.reads, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(source.reads, 2);
      controller.pause();
      await tester.pump(const Duration(seconds: 3));
      expect(source.reads, 2);
      controller.start();
      await tester.pump();
      expect(source.reads, 3);
      controller.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(source.reads, 3);
    },
  );

  testWidgets(
    'Empty, single and missing points render and selection survives window changes',
    (tester) async {
      Future<void> show(List<double?> values, List<double> times) =>
          tester.pumpWidget(
            MaterialApp(
              home: StatisticsPage(
                series: [
                  StatisticSeries(
                    title: 'Pomiar',
                    unit: 'GB',
                    minimum: 0,
                    maximum: 4,
                    values: values,
                    secondsAgo: times,
                  ),
                ],
              ),
            ),
          );
      await show([], []);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-reading-Pomiar')))
            .data,
        'Brak danych',
      );
      await show([2], [0]);
      await tester.tap(
        find.descendant(
          of: find.byType(StatisticLineChart).first,
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await show([null, 2, null], [-3, -1, 0]);
      await show([], []);
      expect(tester.takeException(), isNull);
    },
  );
}
