import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/llm_settings_page.dart';

void main() {
  group('Settings save action', () {
    for (final valid in [false, true]) {
      testWidgets(
        valid ? 'Saves valid settings' : 'Does not save invalid settings',
        (tester) async {
          final draft = LlmSettingsDraft(defaultLlmConfiguration);
          LlmConfiguration? saved;
          await tester.pumpWidget(
            MaterialApp(
              home: LlmSettingsPage(
                draft: draft,
                onSave: (configuration) async {
                  saved = configuration;
                },
              ),
            ),
          );
          draft.fields['contextSize']!.text = valid ? '4096' : 'invalid';
          draft.fields['numberOfThreads']!.text = '2';

          await tester.tap(find.text('Zapisz'));
          await tester.pumpAndSettle();

          if (valid) {
            expect(saved!.contextSize, 4096);
            expect(saved!.numberOfThreads, 2);
          } else {
            expect(saved, isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          draft.dispose();
        },
      );
    }
  });
}
