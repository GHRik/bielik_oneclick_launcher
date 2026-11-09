import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/statistics_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/statistics/statistic_card.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.series, this.controller});

  final List<StatisticSeries> series;
  final StatisticsController? controller;

  @override
  Widget build(BuildContext context) {
    final source = controller;
    if (source == null) return _content(context, series);
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) => _content(context, source.series),
    );
  }

  Widget _content(BuildContext context, List<StatisticSeries> series) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Statystyki')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, -0.6),
            radius: 1.8,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Jak pracuje Bielik',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ostatnie 60 sekund · historia bieżącej sesji',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(14) / 14;
                        final columns =
                            constraints.maxWidth >= 320 &&
                            constraints.maxWidth / textScale >= 300;
                        final cardWidth = columns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < series.length; i++)
                              SizedBox(
                                width: i == 0
                                    ? constraints.maxWidth
                                    : cardWidth,
                                child: StatisticCard(
                                  key: ValueKey(series[i].title),
                                  series: series[i],
                                  highlighted: i == 0,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pomiary co sekundę, gdy aplikacja jest na pierwszym '
                      'planie. Brak dostępnego pomiaru oznaczamy kreską.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
