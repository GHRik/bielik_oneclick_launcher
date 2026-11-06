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

  @override
  Widget build(BuildContext context) {
    final available = availableGb;
    final requirementStatus = ResourceRequirement(
      requiredGb: requiredGb,
      availableGb: available,
    ).status;
    final hasData = requirementStatus != RequirementStatus.unknown;
    final enough = requirementStatus == RequirementStatus.sufficient;
    final color = !hasData
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : enough
        ? Colors.green.shade800
        : Colors.red.shade800;
    final background = !hasData
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : enough
        ? Colors.green.shade50
        : Colors.red.shade50;
    final status = !hasData
        ? 'Brak danych'
        : enough
        ? 'Wystarczająco'
        : 'Za mało';
    final value = hasData
        ? available!.toStringAsFixed(2).replaceAll('.', ',')
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(requirement, style: TextStyle(color: color)),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  !hasData
                      ? Icons.help_outline
                      : enough
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$availableLabel: $value GB',
                        style: TextStyle(color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
