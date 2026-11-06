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
  });

  final BielikModel model;
  final double? availableStorageGb;
  final double? availableRamGb;

  @override
  Widget build(BuildContext context) {
    final requirements = ModelRequirements.evaluate(
      model, availableStorageGb: availableStorageGb, availableRamGb: availableRamGb,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wymagania modelu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RequirementStatusRow(
              requirement: 'Miejsce na dysku: ${model.diskSpace}',
              availableLabel: 'Wolne miejsce u Ciebie',
              requiredGb: requirements.storage.requiredGb,
              availableGb: availableStorageGb,
            ),
            const SizedBox(height: 8),
            RequirementStatusRow(
              requirement: 'RAM (szacunkowo): ${model.ram}',
              availableLabel: 'Dostępny RAM u Ciebie',
              requiredGb: requirements.ram.requiredGb,
              availableGb: availableRamGb,
            ),
            const SizedBox(height: 12),
            const Text(
              'Zużycie RAM zależy od długości rozmowy i silnika AI.',
            ),
          ],
        ),
      ),
    );
  }
}
