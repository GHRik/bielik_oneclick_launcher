import 'package:bielik_oneclick_launcher/src/data/datasources/statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/sampling_statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/generation_metrics.dart';

class LocalStatisticsRepository implements SamplingStatisticsRepository {
  LocalStatisticsRepository(
    this._source,
    this._generation, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final StatisticsDataSource _source;
  final GenerationMetrics _generation;
  final DateTime Function() _now;
  final List<({DateTime time, List<double?> values})> _samples = [];

  @override
  Future<List<StatisticSeries>> sample() async {
    Map<String, dynamic> values;
    try {
      values = await _source.read();
    } catch (_) {
      values = {};
    }
    double? number(String key) {
      final value = values[key];
      return value is num && value.isFinite && value >= 0
          ? value.toDouble()
          : null;
    }

    double? boundedNumber(String key, double maximum) {
      final value = number(key);
      return value != null && value <= maximum ? value : null;
    }

    final now = _now();
    _samples.add((
      time: now,
      values: [
        _generation.tokensPerSecond,
        _generation.firstResponseSeconds,
        number('appRamBytes') == null
            ? null
            : number('appRamBytes')! / 1000000000,
        _generation.completedTokens?.toDouble(),
        number('cpuTemperature'),
        number('batteryTemperature'),
        number('appCpuPercent'),
        boundedNumber('gpuUsagePercent', 100),
        boundedNumber('gpuTemperature', 200),
      ],
    ));
    _samples.removeWhere(
      (sample) => now.difference(sample.time).inMilliseconds > 60000,
    );
    if (_samples.length > 61) _samples.removeRange(0, _samples.length - 61);
    return getSeries();
  }

  @override
  List<StatisticSeries> getSeries() {
    final now = _now();
    final samples = _samples
        .where((s) => now.difference(s.time).inMilliseconds <= 60000)
        .toList();
    const definitions = [
      (
        'Prędkość generowania',
        'tok./s',
        40.0,
        'Średnia ostatniej odpowiedzi: tokeny / czas żądania silnika, łącznie z przetwarzaniem kontekstu. Aktualizacja po zakończeniu.',
      ),
      (
        'Czas do pierwszej odpowiedzi',
        's',
        10.0,
        'Od rozpoczęcia żądania LLM do pierwszego tekstu, łącznie z ładowaniem modelu. Ostatnia odpowiedź.',
      ),
      (
        'RAM aplikacji',
        'GB',
        1.0,
        'Pamięć PSS procesu aplikacji, w tym silnik i model.',
      ),
      (
        'Wygenerowane tokeny',
        'tokeny',
        512.0,
        'Suma tokenów raportowanych przez silnik w tej sesji aplikacji. Aktualizacja po zakończeniu odpowiedzi; przerwane bez raportu są pomijane.',
      ),
      (
        'Temperatura CPU',
        '°C',
        80.0,
        'Brak danych oznacza, że Android nie udostępnia odczytu tej aplikacji.',
      ),
      (
        'Temperatura baterii',
        '°C',
        60.0,
        'Temperatura baterii; jest osobnym pomiarem od temperatury CPU.',
      ),
      (
        'CPU aplikacji',
        '%',
        100.0,
        'Udział aplikacji w łącznej mocy wszystkich dostępnych rdzeni CPU.',
      ),
      (
        'Użycie GPU',
        '%',
        100.0,
        'Obciążenie całego GPU telefonu. Brak danych oznacza, że sterownik nie udostępnia licznika aplikacji.',
      ),
      (
        'Temperatura GPU',
        '°C',
        100.0,
        'Odczyt czujnika GPU, jeśli system udostępnia go aplikacji.',
      ),
    ];
    return List.generate(definitions.length, (i) {
      final values = samples.map((s) => s.values[i]).toList();
      final maximum = values.whereType<double>().fold<double>(
        definitions[i].$3,
        (max, value) => value > max ? value : max,
      );
      return StatisticSeries(
        title: definitions[i].$1,
        unit: definitions[i].$2,
        description: definitions[i].$4,
        minimum: 0,
        maximum: maximum,
        values: List.unmodifiable(values),
        secondsAgo: List.unmodifiable(
          samples.map((s) => -now.difference(s.time).inMicroseconds / 1000000),
        ),
      );
    });
  }
}
