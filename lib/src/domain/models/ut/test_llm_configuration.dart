import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';

void main() {
  group('LlmConfiguration', () {
    test('copyWith preserves fields omitted from the override', () {
      const original = LlmConfiguration(
        contextSize: 2048,
        responseTokens: 512,
        safetyTokens: 32,
        numberOfThreads: 4,
        batchSize: 128,
        temperature: 0.8,
        topK: 40,
        topP: 0.9,
        minP: 0,
        repeatPenalty: 1.1,
      );

      final updated = original.copyWith(
        contextSize: 4096,
        responseTokens: 1024,
        numberOfThreads: 2,
        temperature: 0.5,
      );

      expect(updated.batchSize, original.batchSize);
    });
  });
}
