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
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: ChipTheme(
        data: ChipTheme.of(context).copyWith(
          labelStyle: Theme.of(context).textTheme.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(Icons.translate, size: 16),
              label: const Text('Przetłumacz'),
              onPressed: onTranslate,
            ),
            ActionChip(
              avatar: const Icon(Icons.summarize_outlined, size: 16),
              label: const Text('Streść'),
              onPressed: onSummarize,
            ),
            ActionChip(
              avatar: const Icon(Icons.manage_search, size: 16),
              label: const Text('Analizuj'),
              onPressed: onAnalyze,
            ),
          ],
        ),
      ),
    ),
  );
}
