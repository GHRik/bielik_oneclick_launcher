import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/glass_statistic_surface.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_line_chart.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({super.key, required this.series});

  final StatisticSeries series;

  String _reading(double? value) {
    if (value == null || !value.isFinite) return '0';
    return value
        .toStringAsFixed(value == value.roundToDouble() ? 0 : 1)
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = series.values.isEmpty ? null : series.values.last;
    return GlassStatisticSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            series.title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              height: 1.25,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _reading(value),
                key: ValueKey('statistic-value-${series.title}'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                series.unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatisticLineChart(series: series, height: 64),
        ],
      ),
    );
  }
}
