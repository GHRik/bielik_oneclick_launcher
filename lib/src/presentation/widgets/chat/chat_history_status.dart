import 'package:material_ui/material_ui.dart';

class ChatHistoryStatus extends StatelessWidget {
  const ChatHistoryStatus({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Wczytywanie rozmów…'),
            ] else ...[
              Text(error ?? 'Nie udało się otworzyć historii rozmów.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
