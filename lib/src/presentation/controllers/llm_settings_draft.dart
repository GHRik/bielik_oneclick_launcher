import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';

class LlmSettingsDraft {
  LlmSettingsDraft(this.defaults) {
    reset();
    save();
  }

  final LlmConfiguration defaults;
  final fields = <String, TextEditingController>{};
  Map<String, String> _saved = {};

  void save() {
    _saved = fields.map((key, value) => MapEntry(key, value.text));
  }

  void restoreSaved() {
    for (final entry in _saved.entries) {
      fields[entry.key]!.text = entry.value;
    }
  }

  static const labels = <String, String>{
    'contextSize': 'Rozmiar kontekstu (tokeny)',
    'responseTokens': 'Maksymalna odpowiedź (tokeny)',
    'safetyTokens': 'Zapas kontekstu (tokeny)',
    'numberOfThreads': 'Liczba wątków CPU',
    'batchSize': 'Rozmiar partii',
    'temperature': 'Temperatura',
    'topK': 'Top K',
    'topP': 'Top P',
    'minP': 'Min P',
    'repeatPenalty': 'Kara za powtórzenia',
    'seed': 'Seed (opcjonalny)',
  };

  static const decimalFields = {'temperature', 'topP', 'minP', 'repeatPenalty'};

  void reset() {
    final values = <String, Object?>{
      'contextSize': defaults.contextSize,
      'responseTokens': defaults.responseTokens,
      'safetyTokens': defaults.safetyTokens,
      'numberOfThreads': defaults.numberOfThreads,
      'batchSize': defaults.batchSize,
      'temperature': defaults.temperature,
      'topK': defaults.topK,
      'topP': defaults.topP,
      'minP': defaults.minP,
      'repeatPenalty': defaults.repeatPenalty,
      'seed': defaults.seed,
    };
    for (final entry in values.entries) {
      final controller = fields.putIfAbsent(
        entry.key,
        () => TextEditingController(),
      );
      controller.text = entry.value?.toString() ?? '';
    }
  }

  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
  }
}
