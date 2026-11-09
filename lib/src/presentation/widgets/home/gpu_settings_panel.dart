import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/parameter_help_button.dart';

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
                  suffixIcon: ParameterHelpButton(
                    title: 'Backend GPU',
                    description: 'Sposób komunikacji z GPU: Vulkan lub OpenCL. Wydajność i zgodność zależą od sterownika telefonu; GPU nie zawsze jest szybsze od CPU.',
                  ),
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
                  suffixIcon: ParameterHelpButton(
                    title: 'Limit warstw GPU',
                    description: 'Maksymalna liczba warstw modelu przenoszonych na GPU. Większy limit może zwiększyć zużycie pamięci; rzeczywista liczba zależy od modelu i silnika.',
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: draft.microBatch,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mikropartia GPU',
                  suffixIcon: ParameterHelpButton(
                    title: 'Mikropartia GPU',
                    description: 'Liczba tokenów przetwarzanych jednocześnie wewnątrz partii. Większa wartość może przyspieszyć analizę tekstu, ale wymaga więcej pamięci.',
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Flash Attention'),
                secondary: const ParameterHelpButton(
                  title: 'Flash Attention',
                  description: 'Optymalizacja mechanizmu uwagi, która może ograniczyć zużycie pamięci i przyspieszyć obliczenia. Dostępność zależy od modelu i backendu.',
                ),
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
