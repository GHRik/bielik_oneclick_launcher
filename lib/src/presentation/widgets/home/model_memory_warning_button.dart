import 'package:material_ui/material_ui.dart';

class ModelMemoryWarningButton extends StatefulWidget {
  const ModelMemoryWarningButton({super.key, required this.modelName});

  final String modelName;

  @override
  State<ModelMemoryWarningButton> createState() =>
      _ModelMemoryWarningButtonState();
}

class _ModelMemoryWarningButtonState extends State<ModelMemoryWarningButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _opacity = Tween<double>(begin: 0.55, end: 1).animate(_pulse);
  late final _scale = Tween<double>(begin: 0.9, end: 1.15).animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Informacja o pamięci RAM',
    icon: FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: const Icon(
          Icons.warning_amber_rounded,
          size: 24,
          color: Color(0xFFFF1744),
        ),
      ),
    ),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pamięć RAM modelu'),
        content: Text(
          '${widget.modelName} może wymagać więcej RAM, niż jest dostępne na Twoim telefonie. '
          'Przy braku pamięci podczas ładowania lub rozmowy aplikacja może się zamknąć. '
          'Jeśli tak się dzieje, wybierz mniejszy model lub zmniejsz kontekst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    ),
  );
}
