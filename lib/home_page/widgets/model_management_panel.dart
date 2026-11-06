import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/home_page/controllers/download_preview_controller.dart';
import 'package:bielik_oneclick_launcher/home_page/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/home_page/widgets/download_progress_card.dart';
import 'package:bielik_oneclick_launcher/home_page/widgets/model_requirements_card.dart';

class ModelManagementPanel extends StatefulWidget {
  const ModelManagementPanel({super.key});

  @override
  State<ModelManagementPanel> createState() => _ModelManagementPanelState();
}

class _ModelManagementPanelState extends State<ModelManagementPanel> {
  final _download = DownloadPreviewController();
  BielikModel _selectedModel = bielikModels.first;

  void _selectModel(BielikModel? model) {
    if (model == null) return;
    setState(() => _selectedModel = model);
    _download.reset();
  }

  void _showDeletePreview() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Usuwanie modeli będzie dostępne wkrótce.'),
        ),
      );
  }

  @override
  void dispose() {
    _download.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _download,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wybierz model Bielika',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<BielikModel>(
            initialValue: _selectedModel,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final model in bielikModels)
                DropdownMenuItem(value: model, child: Text(model.name)),
            ],
            onChanged: _download.isRunning ? null : _selectModel,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _download.isRunning
                      ? null
                      : () => _download.start(_selectedModel.downloadSizeMb),
                  icon: const Icon(Icons.download),
                  label: Text(
                    _download.isRunning ? '${_download.percent}%' : 'Pobierz',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _download.isRunning ? null : _showDeletePreview,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Usuń'),
                ),
              ),
            ],
          ),
          if (_download.visible) ...[
            const SizedBox(height: 16),
            DownloadProgressCard(preview: _download),
          ],
          const SizedBox(height: 24),
          ModelRequirementsCard(model: _selectedModel),
        ],
      ),
    );
  }
}
