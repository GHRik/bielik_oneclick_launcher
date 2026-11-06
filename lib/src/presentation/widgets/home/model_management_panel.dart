import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/download_confirmation_dialog.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/download_progress_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_requirements_card.dart';

class ModelManagementPanel extends StatefulWidget {
  const ModelManagementPanel({
    super.key,
    required this.models,
    required this.repository,
    this.onModelSelected,
    this.availableStorageGb,
    this.availableRamGb,
  });

  final List<BielikModel> models;
  final ModelFilesRepository repository;
  final ValueChanged<BielikModel>? onModelSelected;
  final double? availableStorageGb;
  final double? availableRamGb;

  @override
  State<ModelManagementPanel> createState() => _ModelManagementPanelState();
}

class _ModelManagementPanelState extends State<ModelManagementPanel> {
  late final _download = ModelDownloadController(widget.repository);
  late BielikModel _selectedModel = widget.models.first;
  bool _downloadDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _download.select(_selectedModel);
  }

  bool _hasEnough(double? available, double requiredGb) =>
      ResourceRequirement(
        requiredGb: requiredGb,
        availableGb: available,
      ).status ==
      RequirementStatus.sufficient;

  Future<void> _requestDownload() async {
    if (_download.isRunning ||
        _download.checking ||
        _download.complete ||
        _downloadDialogOpen) {
      return;
    }
    final model = _selectedModel;
    final meetsRequirements =
        _hasEnough(widget.availableStorageGb, model.downloadSizeMb / 1000) &&
        _hasEnough(widget.availableRamGb, model.requiredFreeRamGb);

    if (!meetsRequirements) {
      _downloadDialogOpen = true;
      bool? confirmed;
      try {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => DownloadConfirmationDialog(modelName: model.name),
        );
      } finally {
        _downloadDialogOpen = false;
      }
      if (!mounted || confirmed != true) return;
    }
    await _download.start(model);
  }

  void _selectModel(BielikModel? model) {
    if (model == null || _download.busy || _download.checking) return;
    setState(() => _selectedModel = model);
    widget.onModelSelected?.call(model);
    _download.select(model);
  }

  Future<void> _deleteModel() async {
    final model = _selectedModel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć model?'),
        content: Text(
          'Plik modelu ${model.name} zostanie usunięty z telefonu. Rozmowy pozostaną zapisane.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _download.delete(model);
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
              for (final model in widget.models)
                DropdownMenuItem(value: model, child: Text(model.name)),
            ],
            onChanged:
                _download.busy || _download.checking || _downloadDialogOpen
                ? null
                : _selectModel,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _download.busy || _download.checking || _download.complete
                      ? null
                      : _requestDownload,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _download.complete
                        ? 'Pobrano'
                        : _download.isRunning
                        ? '${_download.percent}%'
                        : 'Pobierz',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _download.busy ||
                          _download.checking ||
                          !_download.complete
                      ? null
                      : _deleteModel,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Usuń'),
                ),
              ),
            ],
          ),
          if (_download.visible) ...[
            const SizedBox(height: 16),
            DownloadProgressCard(download: _download),
          ],
          if (_download.complete && !_download.visible) ...[
            const SizedBox(height: 12),
            const Text('Model pobrany na telefon.'),
          ],
          if (_download.error != null) ...[
            const SizedBox(height: 12),
            Text(
              _download.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (_download.checking == false && !_download.busy)
              TextButton(
                onPressed: () => _download.select(_selectedModel),
                child: const Text('Sprawdź ponownie'),
              ),
          ],
          const SizedBox(height: 24),
          ModelRequirementsCard(
            model: _selectedModel,
            availableStorageGb: widget.availableStorageGb,
            availableRamGb: widget.availableRamGb,
          ),
        ],
      ),
    );
  }
}
