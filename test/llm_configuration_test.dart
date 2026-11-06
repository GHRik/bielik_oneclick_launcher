import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/configured_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

void main() {
  test('Models without overrides use the common configuration', () {
    for (final model in bielikModels) {
      expect(llmConfigurationFor(model.file!), same(defaultLlmConfiguration));
    }
    expect(
      const ConfiguredModelCatalogRepository(bielikModels).getModels(),
      bielikModels,
    );
  });

  test(
    'An override changes only its model and preserves the other defaults',
    () async {
      final model = bielikModels.last.file!;
      final configuration = defaultLlmConfiguration.copyWith(
        contextSize: 4096,
        responseTokens: 1024,
        numberOfThreads: 2,
        temperature: 0.5,
      );
      modelLlmConfigurations[model.name] = configuration;
      addTearDown(() => modelLlmConfigurations.remove(model.name));
      expect(llmConfigurationFor(model), same(configuration));
      expect(
        llmConfigurationFor(bielikModels.first.file!),
        same(defaultLlmConfiguration),
      );
      expect(configuration.batchSize, defaultLlmConfiguration.batchSize);
      expect(configuration.useGpu, defaultLlmConfiguration.useGpu);
      final policy = ChatContextPolicy(
        contextSize: configuration.contextSize,
        responseTokens: configuration.responseTokens,
        safetyTokens: configuration.safetyTokens,
      );
      expect(policy.promptBudget, 3040);
    },
  );
}
