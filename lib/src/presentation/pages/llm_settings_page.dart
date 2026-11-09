import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/parameter_help_button.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/theme_preference_card.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/gpu_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/gpu_settings_draft.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/gpu_settings_panel.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';

class LlmSettingsPage extends StatefulWidget {
  const LlmSettingsPage({
    super.key,
    required this.draft,
    this.onSave,
    this.gpuConfiguration = const GpuConfiguration(),
    this.onSaveGpu,
  });

  final LlmSettingsDraft draft;
  final GpuConfiguration gpuConfiguration;
  final ValueChanged<GpuConfiguration>? onSaveGpu;
  final Future<void> Function(LlmConfiguration)? onSave;

  @override
  State<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends State<LlmSettingsPage> {
  LlmSettingsDraft get draft => widget.draft;
  late final _gpuDraft = GpuSettingsDraft(widget.gpuConfiguration);
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final configuration = draft.configuration();
      final gpu = _gpuDraft.configuration(configuration.batchSize);
      await widget.onSave?.call(configuration);
      widget.onSaveGpu?.call(gpu);
      if (!mounted) return;
      draft.save();
      Navigator.of(context).pop();
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Nie udało się zapisać ustawień. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    draft.restoreSaved();
  }

  @override
  void dispose() {
    _gpuDraft.dispose();
    super.dispose();
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

  static const _help = {
    'contextSize': 'Ile tokenów model może uwzględnić naraz, łącznie z rozmową, załącznikami i odpowiedzią. Większy kontekst zużywa więcej RAM.',
    'responseTokens': 'Maksymalna liczba tokenów nowej odpowiedzi. Większy limit zostawia mniej miejsca na tekst wejściowy.',
    'safetyTokens': 'Rezerwa tokenów na narzut formatu rozmowy. Nie jest dostępna dla treści wiadomości ani odpowiedzi.',
    'numberOfThreads': 'Liczba wątków CPU używanych do obliczeń. Więcej wątków nie zawsze oznacza szybszą odpowiedź.',
    'batchSize': 'Maksymalna liczba tokenów w partii przetwarzania tekstu wejściowego. Większa partia może przyspieszyć analizę, ale zwiększa zużycie pamięci.',
    'temperature': 'Niższa wartość daje bardziej przewidywalne odpowiedzi. Wyższa zwiększa różnorodność wybieranych tokenów.',
    'topK': 'Ogranicza wybór następnego tokenu do K najbardziej prawdopodobnych kandydatów. Wartość 0 wyłącza ten filtr.',
    'topP': 'Ogranicza wybór do tokenów, których łączne prawdopodobieństwo osiąga ustawiony próg. Niższa wartość zawęża wybór.',
    'minP': 'Odrzuca tokeny zbyt mało prawdopodobne względem najlepszego kandydata. Wartość 0 wyłącza ten filtr.',
    'repeatPenalty': 'Ogranicza powtarzanie tokenów. Wartość 1 nie nakłada kary; zbyt wysoka może pogorszyć odpowiedzi.',
    'seed': 'Ziarno losowania. Ta sama wartość pomaga odtwarzać wyniki przy identycznych ustawieniach i środowisku. Puste pole oznacza losowe ziarno.',
  };

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
        suffixIcon: ParameterHelpButton(
          title: LlmSettingsDraft.labels[name]!,
          description: _help[name]!,
        ),
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
          onPressed: _saving ? null : _save,
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
                const ThemePreferenceCard(),
                const SizedBox(height: 16),
                const Text(
                  'Ustawienia wspólne dla modeli. Zapisz zmiany, aby użyć ich '
                  'przy następnym otwarciu czatu.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
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
                GpuSettingsPanel(draft: _gpuDraft),
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
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          draft.reset();
                          _gpuDraft.reset();
                        }),
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
