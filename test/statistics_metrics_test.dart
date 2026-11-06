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
  test('Measures RAM aplikacji through the statistics adapter', () async {
    final metrics = GenerationMetrics();
    final repository = LocalStatisticsRepository(_Source(), metrics);
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'RAM aplikacji')
        .values
        .single;
    expect(value, 2.5);
  });
  test('Measures CPU aplikacji through the statistics adapter', () async {
    final metrics = GenerationMetrics();
    final repository = LocalStatisticsRepository(_Source(), metrics);
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'CPU aplikacji')
        .values
        .single;
    expect(value, 25);
  });
  test('Measures Temperatura CPU through the statistics adapter', () async {
    final metrics = GenerationMetrics();
    final repository = LocalStatisticsRepository(_Source(), metrics);
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'Temperatura CPU')
        .values
        .single;
    expect(value, 48.5);
  });
  test('Measures Temperatura baterii through the statistics adapter', () async {
    final metrics = GenerationMetrics();
    final repository = LocalStatisticsRepository(_Source(), metrics);
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'Temperatura baterii')
        .values
        .single;
    expect(value, 36.5);
  });
  test(
    'Measures Czas do pierwszej odpowiedzi through the statistics adapter',
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
}
