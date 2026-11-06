import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';

class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({super.key, required this.download});

  final ModelDownloadController download;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              download.complete
                  ? 'Pobieranie zakończone · 100%'
                  : download.verifying
                  ? 'Sprawdzanie poprawności pliku…'
                  : 'Pobieranie · ${download.percent}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: download.verifying ? null : download.progress,
              semanticsLabel: 'Postęp pobierania',
              semanticsValue: '${download.percent}%',
            ),
            if (!download.complete && !download.verifying) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('Prędkość: ${download.speed} MB/s'),
                  Text('Pozostało (ETA): ${download.remainingTime}'),
                ],
              ),
            ],
            if (download.isRunning)
              TextButton(
                onPressed: download.cancel,
                child: const Text('Anuluj pobieranie'),
              ),
          ],
        ),
      ),
    );
  }
}
