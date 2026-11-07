import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _ModelRepository implements ModelCatalogRepository {
  const _ModelRepository();

  @override
  List<BielikModel> getModels() => const [
    BielikModel(
      name: 'Testowy model',
      diskSpace: 'około 1 GB',
      downloadSizeMb: 1000,
      ram: '2 GB',
      requiredFreeRamGb: 2,
    ),
  ];
}

class _StatisticsRepository implements StatisticsRepository {
  const _StatisticsRepository();

  @override
  List<StatisticSeries> getSeries() => const [
    StatisticSeries(
      title: 'Testowa metryka',
      unit: 's',
      minimum: 0,
      maximum: 3,
      values: [1, 2, 3],
    ),
  ];
}

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MyApp(
      modelFilesRepository: InMemoryModelFilesRepository(),
      chatRepository: InMemoryChatRepository(),
      modelRepository: _ModelRepository(),
      statisticsRepository: _StatisticsRepository(),
    ),
  );
}

void main() {
  group('Repository injection into views', () {
    testWidgets('Home displays models supplied by the catalog contract', (
      tester,
    ) async {
      await _openApp(tester);

      expect(find.text('Testowy model'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Statistics displays only series supplied by its repository', (
      tester,
    ) async {
      await _openApp(tester);
      await tester.tap(find.text('Otwórz czat'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Statystyki'));
      await tester.pumpAndSettle();

      expect(find.text('Testowa metryka'), findsOneWidget);
      expect(find.text('Prędkość generowania'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
