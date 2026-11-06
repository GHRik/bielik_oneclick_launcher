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
    return Scaffold(
      appBar: AppBar(title: const Text('Statystyki')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Wydajność modelu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ostatnie 60 sekund · pomiary co sekundę podczas działania aplikacji na pierwszym planie. Historia bieżącej sesji.',
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final statistic in [
                            ...series,
                            const StatisticSeries(
                              title: 'Użycie GPU',
                              unit: '%',
                              minimum: 0,
                              maximum: 100,
                              values: [],
                              description: 'Pomiar niedostępny.',
                            ),
                            const StatisticSeries(
                              title: 'Temperatura GPU',
                              unit: '°C',
                              minimum: 0,
                              maximum: 100,
                              values: [],
                              description: 'Pomiar niedostępny.',
                            ),
                          ])
                            SizedBox(
                              width: cardWidth,
                              child: StatisticCard(series: statistic),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
