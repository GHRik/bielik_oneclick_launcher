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
  group('GPU statistics adapter', () {
    for (final entry in <String, (String, double)>{
      'gpuUsagePercent': ('Użycie GPU', 37.5),
      'gpuTemperature': ('Temperatura GPU', 56.25),
    }.entries) {
      testWidgets('Displays ${entry.key} in its chart', (tester) async {
        final source = FakeStatisticsSource()
          ..values = {entry.key: entry.value.$2};
        final controller = StatisticsController(
          LocalStatisticsRepository(source, GenerationMetrics()),
        );
        await controller.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: StatisticsPage(series: const [], controller: controller),
          ),
        );

        final chart = tester
            .widgetList<StatisticLineChart>(find.byType(StatisticLineChart))
            .singleWhere((widget) => widget.series.title == entry.value.$1);
        expect(find.text(entry.value.$1), findsOneWidget);
        expect(chart.series.values, [entry.value.$2]);

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });

      test('Accepts a zero ${entry.key} reading', () async {
        final source = FakeStatisticsSource()..values = {entry.key: 0};
        final repository = LocalStatisticsRepository(
          source,
          GenerationMetrics(),
        );

        final series = await repository.sample();

        expect(series.singleWhere((s) => s.title == entry.value.$1).values, [
          0,
        ]);
      });
    }

    for (final entry in <String, (String, double)>{
      'gpuUsagePercent': ('Użycie GPU', 101),
      'gpuTemperature': ('Temperatura GPU', double.nan),
    }.entries) {
      test('Leaves a gap for an invalid ${entry.key} reading', () async {
        final source = FakeStatisticsSource()
          ..values = {entry.key: entry.value.$2};
        final repository = LocalStatisticsRepository(
          source,
          GenerationMetrics(),
        );

        final series = await repository.sample();

        expect(series.singleWhere((s) => s.title == entry.value.$1).values, [
          null,
        ]);
      });
    }
  });

  group('Statistics history sampling', () {
    late DateTime now;
    late FakeStatisticsSource source;
    late GenerationMetrics metrics;
    late LocalStatisticsRepository repository;

    setUp(() {
      now = DateTime(2026);
      source = FakeStatisticsSource();
      metrics = GenerationMetrics();
      repository = LocalStatisticsRepository(source, metrics, now: () => now);
    });

    test(
      'Leaves generation speed unknown before a completed response',
      () async {
        final series = await repository.sample();

        expect(
          series.singleWhere((s) => s.title == 'Prędkość generowania').values,
          [null],
        );
      },
    );

    test('Uses engine tokens and duration for generation speed', () async {
      metrics.complete(tokens: 100, duration: const Duration(seconds: 10));

      final series = await repository.sample();

      expect(
        series.singleWhere((s) => s.title == 'Prędkość generowania').values,
        [10],
      );
    });

    test('Accumulates generated tokens across responses', () async {
      metrics.complete(tokens: 100, duration: const Duration(seconds: 10));
      await repository.sample();
      metrics.complete(tokens: 50, duration: const Duration(seconds: 5));
      now = now.add(const Duration(seconds: 1));

      final series = await repository.sample();

      expect(
        series.singleWhere((s) => s.title == 'Wygenerowane tokeny').values.last,
        150,
      );
    });

    test('Uses actual elapsed time for sample positions', () async {
      await repository.sample();
      now = now.add(const Duration(seconds: 4));

      final series = await repository.sample();

      expect(series.first.secondsAgo, [-4, 0]);
    });

    test('Drops samples older than the history window', () async {
      await repository.sample();
      now = now.add(const Duration(seconds: 61));

      final series = await repository.sample();

      expect(series.first.secondsAgo, [0]);
      expect(series.first.values, hasLength(1));
    });

    test('Preserves a valid zero CPU reading', () async {
      source.values = {'appCpuPercent': 0};

      final series = await repository.sample();

      expect(series.singleWhere((s) => s.title == 'CPU aplikacji').values, [0]);
    });

    test('Leaves a gap for a non-finite RAM reading', () async {
      source.values = {'appRamBytes': double.nan};

      final series = await repository.sample();

      expect(series.singleWhere((s) => s.title == 'RAM aplikacji').values, [
        null,
      ]);
    });

    test('Leaves a gap for an unavailable CPU temperature', () async {
      final series = await repository.sample();

      expect(series.singleWhere((s) => s.title == 'Temperatura CPU').values, [
        null,
      ]);
    });

    test('Leaves a gap when the native source fails', () async {
      source.values = {'appCpuPercent': 25};
      await repository.sample();
      source.fail = true;

      final series = await repository.sample();

      expect(series.singleWhere((s) => s.title == 'CPU aplikacji').values, [
        25,
        null,
      ]);
    });
  });

  group('Statistics polling lifecycle', () {
    for (final action in ['foreground', 'pause', 'restart', 'dispose']) {
      testWidgets('Handles $action polling', (tester) async {
        final source = FakeStatisticsSource();
        final controller = StatisticsController(
          LocalStatisticsRepository(source, GenerationMetrics()),
        );
        var disposed = false;
        try {
          controller.start();
          await tester.pump();
          if (action == 'foreground') {
            await tester.pump(const Duration(seconds: 1));
            expect(source.reads, 2);
          } else if (action == 'dispose') {
            controller.dispose();
            disposed = true;
            await tester.pump(const Duration(seconds: 2));
            expect(source.reads, 1);
          } else {
            controller.pause();
            if (action == 'restart') {
              controller.start();
              await tester.pump();
              expect(source.reads, 2);
            } else {
              await tester.pump(const Duration(seconds: 3));
              expect(source.reads, 1);
            }
          }
        } finally {
          if (!disposed) controller.dispose();
        }
      });
    }
  });

  group('Sparse chart rendering', () {
    Future<void> show(
      WidgetTester tester,
      List<double?> values,
      List<double> times,
    ) => tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(
          series: [
            StatisticSeries(
              title: 'Reading',
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

    testWidgets('Displays a no-data label for an empty series', (tester) async {
      await show(tester, [], []);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-reading-Reading')))
            .data,
        'Brak danych',
      );
    });

    testWidgets('Allows selecting a single sample', (tester) async {
      await show(tester, [2], [0]);

      await tester.tap(
        find.descendant(
          of: find.byType(StatisticLineChart).first,
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders missing points without an exception', (tester) async {
      await show(tester, [null, 2, null], [-3, -1, 0]);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Handles an emptied history after a sample was selected', (
      tester,
    ) async {
      await show(tester, [2], [0]);
      await tester.tap(
        find.descendant(
          of: find.byType(StatisticLineChart).first,
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();

      await show(tester, [], []);

      expect(tester.takeException(), isNull);
    });
  });
}
