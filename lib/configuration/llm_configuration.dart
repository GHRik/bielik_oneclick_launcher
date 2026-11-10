import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

const defaultLlmConfiguration = LlmConfiguration(
  contextSize: 2048,
  responseTokens: 512,
  safetyTokens: 32,
  numberOfThreads: 4,
  batchSize: 128,
  temperature: 0.2,
  topK: 40,
  topP: 0.9,
  minP: 0,
  repeatPenalty: 1.2,
);

final modelLlmConfigurations = <String, LlmConfiguration>{};

LlmConfiguration llmConfigurationFor(ModelFile model) =>
    modelLlmConfigurations[model.name] ?? defaultLlmConfiguration;
