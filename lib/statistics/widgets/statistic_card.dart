import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/statistics/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/statistics/widgets/statistic_line_chart.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({super.key, required this.series});

  final StatisticSeries series;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(series.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              series.unit,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            StatisticLineChart(series: series),
          ],
        ),
      ),
    );
  }
}
