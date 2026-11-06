import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/home_page/controllers/download_preview_controller.dart';

class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({super.key, required this.preview});

  final DownloadPreviewController preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              preview.complete
                  ? 'Symulacja zakończona · 100%'
                  : 'Symulacja pobierania · ${preview.percent}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: preview.progress,
              semanticsLabel: 'Postęp symulacji pobierania',
              semanticsValue: '${preview.percent}%',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Prędkość: ${preview.speed} MB/s'),
                Text('Pozostało (ETA): ${preview.remainingTime}'),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Podgląd interfejsu — bez pobierania plików.'),
            if (preview.isRunning)
              TextButton(
                onPressed: preview.reset,
                child: const Text('Anuluj pobieranie'),
              ),
          ],
        ),
      ),
    );
  }
}
