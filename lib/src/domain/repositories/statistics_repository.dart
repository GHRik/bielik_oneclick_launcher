import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';

abstract interface class StatisticsRepository {
  List<StatisticSeries> getSeries();
}
