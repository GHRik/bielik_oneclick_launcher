import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_requirements.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/requirement_status_row.dart';

class ModelRequirementsCard extends StatelessWidget {
  const ModelRequirementsCard({
    super.key,
    required this.model,
    this.availableStorageGb,
    this.availableRamGb,
    this.totalRamGb,
  });

  final BielikModel model;
  final double? availableStorageGb;
  final double? availableRamGb;
  final double? totalRamGb;

  @override
  Widget build(BuildContext context) {
    final requirements = ModelRequirements.evaluate(
      model,
      availableStorageGb: availableStorageGb,
      availableRamGb: availableRamGb,
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zasoby przed pobraniem',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Wymagane / dostępne',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            RequirementStatusRow(
              requirement: 'Pamięć RAM',
              availableLabel: 'Dostępny RAM',
              requiredGb: requirements.ram.requiredGb,
              availableGb: availableRamGb,
            ),
            const SizedBox(height: 20),
            RequirementStatusRow(
              requirement: 'Miejsce na model',
              availableLabel: 'Wolne miejsce',
              requiredGb: requirements.storage.requiredGb,
              availableGb: availableStorageGb,
            ),
          ],
        ),
      ),
    );
  }
}
