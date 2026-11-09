import 'package:material_ui/material_ui.dart';

class ParameterHelpButton extends StatelessWidget {
  const ParameterHelpButton({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Wyjaśnienie: $title',
    icon: const Icon(Icons.info_outline, size: 20),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
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
