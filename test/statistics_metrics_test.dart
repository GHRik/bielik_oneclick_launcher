import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_statistics_repository.dart';

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
    final repository = LocalStatisticsRepository(_Source());
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'RAM aplikacji')
        .values
        .single;
    expect(value, 2.5);
  });
  test('Measures CPU aplikacji through the statistics adapter', () async {
    final repository = LocalStatisticsRepository(_Source());
    final series = await repository.sample();
    final value = series
        .singleWhere((item) => item.title == 'CPU aplikacji')
        .values
        .single;
    expect(value, 25);
  });
}
