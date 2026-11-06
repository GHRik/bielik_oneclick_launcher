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

  LlmConfiguration configuration() {
    int integer(String key, int minimum, [int maximum = 2147483647]) {
      final value = int.tryParse(fields[key]!.text.trim());
      if (value == null || value < minimum || value > maximum) {
        throw FormatException(
          '${labels[key]}: podaj liczbę od $minimum do $maximum.',
        );
      }
      return value;
    }

    double decimal(String key, double minimum, double maximum) {
      final value = double.tryParse(
        fields[key]!.text.trim().replaceAll(',', '.'),
      );
      if (value == null ||
          !value.isFinite ||
          value < minimum ||
          value > maximum) {
        throw FormatException(
          '${labels[key]}: podaj liczbę od $minimum do $maximum.',
        );
      }
      return value;
    }

    final context = integer('contextSize', 128, 131072);
    final response = integer('responseTokens', 1, 131071);
    final safety = integer('safetyTokens', 0, 131071);
    if (context <= response + safety) {
      throw const FormatException(
        'Kontekst musi być większy niż odpowiedź i zapas razem.',
      );
    }
    final seedText = fields['seed']!.text.trim();
    final seed = seedText.isEmpty ? null : int.tryParse(seedText);
    if (seedText.isNotEmpty &&
        (seed == null || seed < 0 || seed > 4294967295)) {
      throw const FormatException(
        'Seed: podaj liczbę od 0 do 4294967295 lub zostaw puste.',
      );
    }
    return LlmConfiguration(
      contextSize: context,
      responseTokens: response,
      safetyTokens: safety,
      numberOfThreads: integer('numberOfThreads', 1, 256),
      batchSize: integer('batchSize', 1, 8192),
      temperature: decimal('temperature', 0, 10),
      topK: integer('topK', 0),
      topP: decimal('topP', 0.000001, 1),
      minP: decimal('minP', 0, 1),
      repeatPenalty: decimal('repeatPenalty', 0.000001, 10),
      seed: seed,
    );
  }

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
