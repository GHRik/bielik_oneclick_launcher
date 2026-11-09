import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';

class _Source extends StatisticsDataSource {
  @override
  Future<Map<String, dynamic>> read() async => {
    'appRamBytes': 2500000000,
    'appCpuPercent': 25,
    'cpuTemperature': 48.5,
    'batteryTemperature': 36.5,
  };
}

void main() {
  group('Statistics adapter metric mapping', () {
    test('Clears first response time when a new request begins', () {
      final metrics = GenerationMetrics()..firstResponseSeconds = 2;

      metrics.begin();

      expect(metrics.firstResponseSeconds, isNull);
    });

    test('Clears generation speed when a new request begins', () {
      final metrics = GenerationMetrics()..tokensPerSecond = 10;

      metrics.begin();

      expect(metrics.tokensPerSecond, isNull);
    });

    test('Measures application RAM through the statistics adapter', () async {
      final metrics = GenerationMetrics();
      final repository = LocalStatisticsRepository(_Source(), metrics);
      final series = await repository.sample();
      final value = series
          .singleWhere((item) => item.title == 'RAM aplikacji')
          .values
          .single;
      expect(value, 2.5);
    });
    test(
      'Measures application CPU usage through the statistics adapter',
      () async {
        final metrics = GenerationMetrics();
        final repository = LocalStatisticsRepository(_Source(), metrics);
        final series = await repository.sample();
        final value = series
            .singleWhere((item) => item.title == 'CPU aplikacji')
            .values
            .single;
        expect(value, 25);
      },
    );
    test('Measures CPU temperature through the statistics adapter', () async {
      final metrics = GenerationMetrics();
      final repository = LocalStatisticsRepository(_Source(), metrics);
      final series = await repository.sample();
      final value = series
          .singleWhere((item) => item.title == 'Temperatura CPU')
          .values
          .single;
      expect(value, 48.5);
    });
    test(
      'Measures battery temperature through the statistics adapter',
      () async {
        final metrics = GenerationMetrics();
        final repository = LocalStatisticsRepository(_Source(), metrics);
        final series = await repository.sample();
        final value = series
            .singleWhere((item) => item.title == 'Temperatura baterii')
            .values
            .single;
        expect(value, 36.5);
      },
    );
    test(
      'Measures time to first response through the statistics adapter',
      () async {
        final metrics = GenerationMetrics();
        metrics.begin();
        metrics.firstText();
        final repository = LocalStatisticsRepository(_Source(), metrics);
        final series = await repository.sample();
        final value = series
            .singleWhere((item) => item.title == 'Czas do pierwszej odpowiedzi')
            .values
            .single;
        expect(value, greaterThanOrEqualTo(0));
      },
    );
    test(
      'Measures generated token count through the statistics adapter',
      () async {
        final metrics = GenerationMetrics();
        metrics.complete(tokens: 100, duration: const Duration(seconds: 10));
        final repository = LocalStatisticsRepository(_Source(), metrics);
        final series = await repository.sample();
        final value = series
            .singleWhere((item) => item.title == 'Wygenerowane tokeny')
            .values
            .single;
        expect(value, 100);
      },
    );
    test('Measures generation speed through the statistics adapter', () async {
      final metrics = GenerationMetrics();
      metrics.complete(tokens: 100, duration: const Duration(seconds: 10));
      final repository = LocalStatisticsRepository(_Source(), metrics);
      final series = await repository.sample();
      final value = series
          .singleWhere((item) => item.title == 'Prędkość generowania')
          .values
          .single;
      expect(value, 10);
    });
  });
}
