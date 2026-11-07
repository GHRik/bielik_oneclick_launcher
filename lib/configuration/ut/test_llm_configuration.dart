import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';

void main() {
  group('Model configuration defaults', () {
    for (final model in bielikModels) {
      test('${model.file!.name} uses the common configuration', () {
        expect(llmConfigurationFor(model.file!), same(defaultLlmConfiguration));
      });
    }
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
  });
}
