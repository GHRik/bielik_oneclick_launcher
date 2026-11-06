import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';

abstract interface class SamplingStatisticsRepository
    implements StatisticsRepository {
  Future<List<StatisticSeries>> sample();
}
