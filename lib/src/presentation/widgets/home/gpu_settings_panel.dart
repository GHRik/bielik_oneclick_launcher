import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/gpu_settings_draft.dart';

class GpuSettingsPanel extends StatefulWidget {
  const GpuSettingsPanel({super.key, required this.draft});
  final GpuSettingsDraft draft;

  @override
  State<GpuSettingsPanel> createState() => _GpuSettingsPanelState();
}

class _GpuSettingsPanelState extends State<GpuSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Akceleracja GPU — eksperymentalna'),
              subtitle: const Text(
                'Tylko bieżąca sesja. Po restarcie aplikacji używane jest CPU.',
              ),
              value: draft.enabled,
              onChanged: (value) => setState(() => draft.enabled = value),
            ),
            if (draft.enabled) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<GpuInferenceBackend>(
                initialValue: draft.backend,
                decoration: const InputDecoration(
                  labelText: 'Backend GPU',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: GpuInferenceBackend.vulkan,
                    child: Text('Vulkan'),
                  ),
                  DropdownMenuItem(
                    value: GpuInferenceBackend.opencl,
                    child: Text('OpenCL'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => draft.backend = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: draft.layers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit warstw GPU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: draft.microBatch,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mikropartia GPU',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Flash Attention'),
                value: draft.flashAttention,
                onChanged: (value) =>
                    setState(() => draft.flashAttention = value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
