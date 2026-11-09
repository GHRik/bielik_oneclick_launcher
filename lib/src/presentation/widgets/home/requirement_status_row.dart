import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';

class RequirementStatusRow extends StatelessWidget {
  const RequirementStatusRow({
    super.key,
    required this.requirement,
    required this.availableLabel,
    required this.requiredGb,
    this.availableGb,
  });

  final String requirement;
  final String availableLabel;
  final double requiredGb;
  final double? availableGb;

  String _gb(double value) =>
      '${value.toStringAsFixed(2).replaceAll('.', ',')} GB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ResourceRequirement(
      requiredGb: requiredGb,
      availableGb: availableGb,
    ).status;
    final hasData = status != RequirementStatus.unknown;
    final insufficient = status == RequirementStatus.insufficient;
    final ratio = !hasData
        ? 0.0
        : availableGb == 0
        ? 1.0
        : requiredGb / availableGb!;
    final color = !hasData
        ? Colors.grey.shade600
        : insufficient
        ? Colors.red.shade700
        : Colors.green.shade700;
    final description = !hasData
        ? 'Brak danych'
        : insufficient
        ? 'Za mało'
        : 'Wystarczająco';

    return Semantics(
      label:
          '$requirement. Wymagane: ${_gb(requiredGb)}. '
          '$availableLabel: ${hasData ? _gb(availableGb!) : "brak danych"}. '
          '$description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(requirement, style: theme.textTheme.bodyMedium),
              Tooltip(
                message: description,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        !hasData
                            ? Icons.remove
                            : insufficient
                            ? Icons.close
                            : Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: insufficient ? 1 : ratio.clamp(0.0, 1.0),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            semanticsLabel: '$requirement · $description',
            semanticsValue:
                '${((insufficient ? 1 : ratio.clamp(0.0, 1.0)) * 100).round()}%',
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Wymagane: ${_gb(requiredGb)} · '
                '$availableLabel: ${hasData ? _gb(availableGb!) : "brak danych"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!hasData || insufficient)
                Text(
                  !hasData
                      ? 'Brak danych'
                      : 'Brakuje ${_gb(requiredGb - availableGb!)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
