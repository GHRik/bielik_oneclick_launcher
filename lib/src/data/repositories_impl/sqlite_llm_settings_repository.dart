import 'dart:convert';

import 'package:bielik_oneclick_launcher/src/data/datasources/local/llm_settings_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_settings_repository.dart';

class SqliteLlmSettingsRepository implements LlmSettingsRepository {
  const SqliteLlmSettingsRepository(this.source);
  final LlmSettingsDataSource source;

  @override
  Future<LlmConfiguration?> load() async {
    final value = await source.load();
    if (value == null) return null;
    final data = jsonDecode(value) as Map<String, dynamic>;
    return LlmConfiguration(
      contextSize: data['contextSize'] as int,
      responseTokens: data['responseTokens'] as int,
      safetyTokens: data['safetyTokens'] as int,
      numberOfThreads: data['numberOfThreads'] as int,
      batchSize: data['batchSize'] as int,
      temperature: (data['temperature'] as num).toDouble(),
      topK: data['topK'] as int,
      topP: (data['topP'] as num).toDouble(),
      minP: (data['minP'] as num).toDouble(),
      repeatPenalty: (data['repeatPenalty'] as num).toDouble(),
      seed: data['seed'] as int?,
    );
  }

  @override
  Future<void> save(LlmConfiguration configuration) => source.save(
    jsonEncode({
      'contextSize': configuration.contextSize,
      'responseTokens': configuration.responseTokens,
      'safetyTokens': configuration.safetyTokens,
      'numberOfThreads': configuration.numberOfThreads,
      'batchSize': configuration.batchSize,
      'temperature': configuration.temperature,
      'topK': configuration.topK,
      'topP': configuration.topP,
      'minP': configuration.minP,
      'repeatPenalty': configuration.repeatPenalty,
      'seed': configuration.seed,
    }),
  );
}
