import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';

void main() {
  group('ContextUsage', () {
    test('Includes input and generated output in the measured usage', () {
      const usage = ContextUsage(
        promptTokens: 300,
        responseTokens: 200,
        contextSize: 1000,
      );
      expect(usage.usedTokens, 500);
    });

    test(
      'Converts measured usage to a percentage of the configured context',
      () {
        const usage = ContextUsage(promptTokens: 250, contextSize: 1000);
        expect(usage.percent, 25);
      },
    );

    test('Caps the displayed fraction at full capacity', () {
      const usage = ContextUsage(promptTokens: 2000, contextSize: 1000);
      expect(usage.fraction, 1);
    });
  });
}
