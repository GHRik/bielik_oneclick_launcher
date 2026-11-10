import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/llm_settings_draft.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/llm_settings_page.dart';

void main() {
  testWidgets('Custom instruction is edited, restored and saved', (
    tester,
  ) async {
    final draft = LlmSettingsDraft(defaultLlmConfiguration);
    addTearDown(draft.dispose);
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: LlmSettingsPage(
          draft: draft,
          additionalSystemPrompt: 'Własna instrukcja',
          onSaveAdditionalSystemPrompt: (value) async => saved = value,
        ),
      ),
    );
    final field = find.byKey(const ValueKey('system-prompt'));
    await tester.ensureVisible(field);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Własna instrukcja',
    );
    await tester.enterText(field, 'Odpowiadaj krótko.');
    expect(saved, isNull);
    final restore = find.text('Wyczyść dodatkowe instrukcje');
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, '');
    await tester.enterText(field, 'Nowa instrukcja');
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(saved, 'Nowa instrukcja');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tapping parameter help opens its explanation', (tester) async {
    final draft = LlmSettingsDraft(defaultLlmConfiguration);
    await tester.pumpWidget(MaterialApp(home: LlmSettingsPage(draft: draft)));

    final help = find.byTooltip('Wyjaśnienie: Rozmiar kontekstu (tokeny)');
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining('Większy kontekst zużywa więcej RAM.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    draft.dispose();
  });

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
