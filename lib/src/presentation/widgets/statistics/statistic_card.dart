import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/glass_statistic_surface.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_line_chart.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.series,
    this.highlighted = false,
  });

  final StatisticSeries series;
  final bool highlighted;

  String _reading(double? value) {
    if (value == null || !value.isFinite) return '—';
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(series.unit, style: theme.textTheme.bodySmall),
            ],
          ),
          if (series.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(series.description, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          StatisticLineChart(series: series, height: highlighted ? 112 : 88),
        ],
      ),
    );
  }
}
