class StatisticSeries {
  const StatisticSeries({
    required this.title,
    required this.unit,
    required this.minimum,
    required this.maximum,
    required this.values,
  });

  final String title;
  final String unit;
  final double minimum;
  final double maximum;
  final List<double> values;
}
