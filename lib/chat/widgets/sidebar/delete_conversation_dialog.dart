import 'package:material_ui/material_ui.dart';

class DeleteConversationDialog extends StatelessWidget {
  const DeleteConversationDialog({super.key, required this.conversationTitle});

  final String conversationTitle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Usunąć rozmowę?'),
      content: Text(
        'Czy na pewno chcesz usunąć rozmowę „$conversationTitle”?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Usuń'),
        ),
      ],
    );
  }
}
