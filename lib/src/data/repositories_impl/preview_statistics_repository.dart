import 'package:bielik_oneclick_launcher/src/data/datasources/preview_statistics_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';

class PreviewStatisticsRepository implements StatisticsRepository {
  const PreviewStatisticsRepository({
    this.dataSource = const PreviewStatisticsDataSource(),
  });

  final PreviewStatisticsDataSource dataSource;

  @override
  List<StatisticSeries> getSeries() =>
      List.unmodifiable(dataSource.getSeries());
}
