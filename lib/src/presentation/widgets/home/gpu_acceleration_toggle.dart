import 'package:material_ui/material_ui.dart';

class GpuAccelerationToggle extends StatelessWidget {
  const GpuAccelerationToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          const Icon(Icons.speed, size: 20),
          const SizedBox(width: 8),
          const Expanded(child: Text('Akceleracja GPU')),
          Switch(value: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}
