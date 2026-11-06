import 'package:material_ui/material_ui.dart';

class DownloadConfirmationDialog extends StatelessWidget {
  const DownloadConfirmationDialog({super.key, required this.modelName});

  final String modelName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Czy na pewno chcesz pobrać?'),
      content: Text(
        '$modelName\n\n'
        'Brakuje danych o telefonie lub wymagania modelu nie są spełnione. '
        'Uruchomienie tego modelu może spowodować znaczne obciążenie telefonu.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Pobierz mimo to'),
        ),
      ],
    );
  }
}
