import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';

class LlmSettingsPage extends StatefulWidget {
  const LlmSettingsPage({super.key, required this.draft});

  final LlmSettingsDraft draft;

  @override
  State<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends State<LlmSettingsPage> {
  LlmSettingsDraft get draft => widget.draft;

  @override
  void initState() {
    super.initState();
    draft.restoreSaved();
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _field(String name) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: draft.fields[name],
      keyboardType: TextInputType.numberWithOptions(
        decimal: LlmSettingsDraft.decimalFields.contains(name),
        signed: name == 'seed',
      ),
      decoration: InputDecoration(
        labelText: LlmSettingsDraft.labels[name],
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Konfiguracja LLM')),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            draft.save();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Zapisz'),
        ),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Podgląd ustawień · tylko interfejs. Zmiany pozostają na tym '
                  'ekranie podczas bieżącej sesji i nie wpływają na model.',
                ),
                const SizedBox(height: 16),
                _section('Kontekst i odpowiedź', [
                  _field('contextSize'),
                  _field('responseTokens'),
                  _field('safetyTokens'),
                ]),
                _section('Wydajność', [
                  _field('numberOfThreads'),
                  _field('batchSize'),
                ]),
                _section('Generowanie tekstu', [
                  _field('temperature'),
                  _field('topK'),
                  _field('topP'),
                  _field('minP'),
                  _field('repeatPenalty'),
                  _field('seed'),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(draft.reset),
                  icon: const Icon(Icons.restore),
                  label: const Text('Przywróć domyślne ustawienia'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
