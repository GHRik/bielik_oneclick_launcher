import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/home_page/models/bielik_model.dart';

class ModelRequirementsCard extends StatelessWidget {
  const ModelRequirementsCard({super.key, required this.model});

  final BielikModel model;

  @override
  Widget build(BuildContext context) {
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Miejsce na dysku: ${model.diskSpace}'),
                const Chip(
                  avatar: Icon(Icons.storage, size: 18),
                  label: Text('Wolne miejsce u Ciebie: — GB'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('RAM (szacunkowo): ${model.ram}'),
                const Chip(
                  avatar: Icon(Icons.memory, size: 18),
                  label: Text('RAM Twojego telefonu: — GB'),
                ),
              ],
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
