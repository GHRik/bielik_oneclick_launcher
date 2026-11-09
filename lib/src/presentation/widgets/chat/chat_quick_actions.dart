import 'package:material_ui/material_ui.dart';

class ChatQuickActions extends StatelessWidget {
  const ChatQuickActions({
    super.key,
    this.onTranslate,
    this.onSummarize,
    this.onAnalyze,
  });

  final VoidCallback? onTranslate;
  final VoidCallback? onSummarize;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ActionChip(label: const Text('Przetłumacz'), onPressed: onTranslate),
        ActionChip(label: const Text('Streść'), onPressed: onSummarize),
        ActionChip(label: const Text('Analizuj'), onPressed: onAnalyze),
      ],
    ),
  );
}
