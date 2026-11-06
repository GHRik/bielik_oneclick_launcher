import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';

const statisticsPreviewData = [
  StatisticSeries(
    title: 'Prędkość generowania',
    unit: 'tok./s',
    minimum: 0,
    maximum: 40,
    values: [16, 18, 21, 20, 24, 22, 19, 23, 25, 22, 24, 21, 23],
  ),
  StatisticSeries(
    title: 'Czas odpowiedzi',
    unit: 's',
    minimum: 0,
    maximum: 3,
    values: [2.1, 1.8, 1.5, 1.7, 1.3, 1.5, 1.9, 1.6, 1.2, 1.4, 1.1, 1.3, 1.2],
  ),
  StatisticSeries(
    title: 'Zużycie RAM',
    unit: 'GB',
    minimum: 0,
    maximum: 4,
    values: [1.6, 1.7, 1.8, 1.8, 1.9, 2, 2.1, 2, 2.2, 2.2, 2.3, 2.2, 2.3],
  ),
  StatisticSeries(
    title: 'Wygenerowane tokeny',
    unit: 'tokeny',
    minimum: 0,
    maximum: 1600,
    values: [0, 80, 180, 280, 390, 500, 600, 710, 830, 940, 1060, 1170, 1300],
  ),
  StatisticSeries(
    title: 'Temperatura CPU',
    unit: '°C',
    minimum: 20,
    maximum: 80,
    values: [34, 36, 38, 41, 44, 46, 49, 52, 54, 56, 55, 53, 51],
  ),
];

class PreviewStatisticsDataSource {
  const PreviewStatisticsDataSource();

  List<StatisticSeries> getSeries() => statisticsPreviewData;
}
