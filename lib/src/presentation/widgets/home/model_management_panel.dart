import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_requirements.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/resource_requirement.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/model_download_controller.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/download_confirmation_dialog.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/download_progress_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_requirements_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_selection_card.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/saved_download_notice.dart';

class ModelManagementPanel extends StatefulWidget {
  const ModelManagementPanel({
    super.key,
    required this.models,
    required this.repository,
    this.onModelSelected,
    this.availableStorageGb,
    this.availableRamGb,
    this.totalRamGb,
    this.onResourcesChanged,
    this.modelOptions,
    this.onSettings,
  });

  final List<BielikModel> models;
  final ModelFilesRepository repository;
  final ValueChanged<BielikModel>? onModelSelected;
  final double? availableStorageGb;
  final double? availableRamGb;
  final double? totalRamGb;
  final Future<void> Function()? onResourcesChanged;
  final Widget? modelOptions;
  final VoidCallback? onSettings;

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

  Future<void> _requestDownload() async {
    if (_download.isRunning ||
        _download.checking ||
        _download.complete ||
        _downloadDialogOpen) {
      return;
    }
    final model = _selectedModel;
    final requirements = ModelRequirements.evaluate(
      model,
      availableStorageGb: _storageForModel(
        widget.availableStorageGb,
        _download.savedBytes,
      ),
      availableRamGb: widget.availableRamGb,
    );

    if (requirements.storage.status == RequirementStatus.insufficient) {
      _downloadDialogOpen = true;
      try {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Za mało miejsca'),
            content: const Text('Proszę zwolnić miejsce, aby pobrać model.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      } finally {
        _downloadDialogOpen = false;
      }
      return;
    }

    if (requirements.requiresConfirmation) {
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
    await widget.onResourcesChanged?.call();
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
    await widget.onResourcesChanged?.call();
  }

  @override
  void dispose() {
    _download.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _download,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _download.complete
                ? 'Twój model.\nGotowy do rozmowy.'
                : 'Wybierz model.\nZacznij rozmowę.',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 24),
          ModelSelectionCard(
            models: widget.models,
            selectedModel: _selectedModel,
            downloaded: _download.complete,
            checking: _download.checking,
            onChanged:
                _download.busy || _download.checking || _downloadDialogOpen
                ? null
                : _selectModel,
          ),
          if (widget.onSettings != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onSettings,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune),
                  SizedBox(width: 12),
                  Expanded(child: Text('Dostosuj model')),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ],
          if (widget.modelOptions != null) ...[
            const SizedBox(height: 12),
            widget.modelOptions!,
          ],
          if (_download.savedBytes > 0 &&
              _selectedModel.file != null &&
              !_download.complete &&
              !_download.busy &&
              !_download.checking) ...[
            const SizedBox(height: 16),
            SavedDownloadNotice(
              savedBytes: _download.savedBytes,
              totalBytes: _selectedModel.file!.sizeBytes,
              onDiscard: () async {
                await _download.delete(_selectedModel);
                await widget.onResourcesChanged?.call();
              },
            ),
          ],
          if (!_download.complete) ...[
            const SizedBox(height: 16),
            ModelRequirementsCard(
              model: _selectedModel,
              availableStorageGb: _storageForModel(
                widget.availableStorageGb,
                _download.savedBytes,
              ),
              availableRamGb: widget.availableRamGb,
              totalRamGb: widget.totalRamGb,
            ),
          ],
          if (_download.visible && !_download.complete) ...[
            const SizedBox(height: 16),
            DownloadProgressCard(download: _download),
          ],
          if (_download.complete) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Wszystko gotowe.\nModel jest na Twoim telefonie. '
                        'Możesz rozmawiać bez internetu.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                tooltip: 'Opcje modelu',
                enabled: !_download.busy && !_download.checking,
                icon: const Icon(Icons.more_vert),
                onSelected: (_) => _deleteModel(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Usuń model')),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _download.busy || _download.checking
                  ? null
                  : _requestDownload,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.download),
              label: Text(
                _download.isRunning ? '${_download.percent}%' : 'Pobierz',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Model pobierasz raz. Później działa lokalnie.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (_download.error != null) ...[
            const SizedBox(height: 12),
            Text(
              _download.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            if (!_download.checking && !_download.busy)
              TextButton(
                onPressed: () => _download.select(_selectedModel),
                child: const Text('Sprawdź ponownie'),
              ),
          ],
        ],
      ),
    );
  }
}

/// Storage that counts for the model: the free space plus the part kept from
/// an interrupted download, which already holds its share of the model. The
/// requirements card and the download check use the same value, so they
/// cannot disagree.
double? _storageForModel(double? freeGb, int savedBytes) =>
    freeGb == null ? null : freeGb + savedBytes / 1000000000;
