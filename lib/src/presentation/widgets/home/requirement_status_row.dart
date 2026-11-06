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
    final requirementStatus =
        ResourceRequirement(requiredGb: requiredGb, availableGb: available).status;
    final hasData = requirementStatus != RequirementStatus.unknown;
    final enough = requirementStatus == RequirementStatus.sufficient;
    final color = !hasData
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : enough ? Colors.green.shade800 : Colors.red.shade800;
    final background = !hasData
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : enough ? Colors.green.shade50 : Colors.red.shade50;
    final status = !hasData
        ? 'Brak danych'
        : enough ? 'Wystarczająco' : 'Za mało';
    final value = hasData
        ? available!.toStringAsFixed(2).replaceAll('.', ',')
        : '—';

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(requirement, style: TextStyle(color: color)),
        Chip(
          backgroundColor: background,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          avatar: Icon(
            !hasData ? Icons.help_outline
                : enough ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 18,
          ),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$availableLabel: $value GB', style: TextStyle(color: color)),
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
