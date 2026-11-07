import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';

void main() {
  group('LLM settings input validation', () {
    for (final entry in <String, String>{
      'responseTokens': '2048',
      'temperature': 'NaN',
      'numberOfThreads': '1.5',
      'seed': '-1',
      'topP': '0',
    }.entries) {
      test('Rejects ${entry.key} = ${entry.value}', () {
        final draft = LlmSettingsDraft(defaultLlmConfiguration);
        addTearDown(draft.dispose);
        draft.fields[entry.key]!.text = entry.value;

        expect(draft.configuration, throwsFormatException);
      });
    }

    test('Accepts a decimal comma in temperature', () {
      final draft = LlmSettingsDraft(defaultLlmConfiguration);
      addTearDown(draft.dispose);
      draft.fields['temperature']!.text = '0,5';

      expect(draft.configuration().temperature, 0.5);
    });
  });
}
