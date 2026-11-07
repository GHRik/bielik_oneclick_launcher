import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/configured_model_catalog_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/chat_context_policy.dart';

void main() {
  group('Model configuration defaults', () {
    for (final model in bielikModels) {
      test('${model.file!.name} uses the common configuration', () {
        expect(llmConfigurationFor(model.file!), same(defaultLlmConfiguration));
      });
    }

    test('The catalog exposes the configured models', () {
      expect(
        const ConfiguredModelCatalogRepository(bielikModels).getModels(),
        bielikModels,
      );
    });
  });

  group('Per-model configuration overrides', () {
    final model = bielikModels.last.file!;
    final configuration = defaultLlmConfiguration.copyWith(
      contextSize: 4096,
      responseTokens: 1024,
      numberOfThreads: 2,
      temperature: 0.5,
    );

    setUp(() {
      modelLlmConfigurations[model.name] = configuration;
    });
    tearDown(() {
      modelLlmConfigurations.remove(model.name);
    });

    test('Uses the override for its model', () {
      expect(llmConfigurationFor(model), same(configuration));
    });

    test('Leaves other models on the common configuration', () {
      expect(
        llmConfigurationFor(bielikModels.first.file!),
        same(defaultLlmConfiguration),
      );
    });

    test('Preserves defaults for fields omitted from copyWith', () {
      expect(configuration.batchSize, defaultLlmConfiguration.batchSize);
    });

    test('Reserves response and safety tokens from the context budget', () {
      final policy = ChatContextPolicy(
        contextSize: configuration.contextSize,
        responseTokens: configuration.responseTokens,
        safetyTokens: configuration.safetyTokens,
      );

      expect(policy.promptBudget, 3040);
    });
  });
}
