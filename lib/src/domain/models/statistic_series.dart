class StatisticSeries {
  static const historySeconds = 120;

  const StatisticSeries({
    required this.title,
    required this.unit,
    required this.minimum,
    required this.maximum,
    required this.values,
    this.secondsAgo = const [],
    this.description = '',
    this.hasRecordedData,
  });

  final String title;
  final String unit;
  final double minimum;
  final double maximum;
  final List<double?> values;
  final List<double> secondsAgo;
  final String description;
  final bool? hasRecordedData;

  bool get isAvailable =>
      hasRecordedData ?? values.any((value) => value != null && value.isFinite);
}
