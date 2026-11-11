import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/formatters/storage_size_formatter.dart';

/// Tells that part of the model is already on the phone after an interrupted
/// download, and lets the user remove it instead of continuing.
class SavedDownloadNotice extends StatelessWidget {
  const SavedDownloadNotice({
    super.key,
    required this.savedBytes,
    required this.totalBytes,
    required this.onDiscard,
  });

  final int savedBytes;
  final int totalBytes;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.downloading, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pobrano już ${StorageSizeFormatter.format(savedBytes)} '
                    'z ${StorageSizeFormatter.format(totalBytes)}.\n'
                    '„Pobierz” dokończy pobieranie od tego miejsca.',
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDiscard,
                child: const Text('Usuń pobraną część'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
