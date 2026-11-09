import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';

class ModelSelectionCard extends StatelessWidget {
  const ModelSelectionCard({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onChanged,
    required this.downloaded,
    required this.checking,
  });

  final List<BielikModel> models;
  final BielikModel selectedModel;
  final ValueChanged<BielikModel?>? onChanged;
  final bool downloaded;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('TWÓJ MODEL', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            DropdownButtonFormField<BielikModel>(
              initialValue: selectedModel,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.titleLarge,
              items: [
                for (final model in models)
                  DropdownMenuItem(value: model, child: Text(model.name)),
              ],
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  checking
                      ? 'Sprawdzanie pliku…'
                      : downloaded
                      ? 'Pobrano'
                      : 'Do pobrania',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: downloaded ? Colors.green.shade700 : null,
                  ),
                ),
                Text(
                  'GGUF · ${selectedModel.diskSpace}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
