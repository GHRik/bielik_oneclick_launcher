import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';

void main() {
  for (final language in TranslationLanguage.values) {
    test('Translation explicitly requests ${language.promptName}', () {
      final prompt = ChatTextAction.translate.prompt(
        'Example',
        targetLanguage: language,
      );
      expect(prompt, contains('na język ${language.promptName}'));
    });
  }

  test('Summarization requests at most three short factual points', () {
    final prompt = ChatTextAction.summarize.prompt('Source');
    expect(prompt, contains('maksymalnie 3 krótkich punktach'));
    expect(prompt, contains('Nie dopisuj faktów, nie przepisuj całości'));
  });

  test('The task follows the complete source text without duplicating it', () {
    const source = 'Pierwszy wiersz.\nDrugi wiersz.';
    final prompt = ChatTextAction.summarize.prompt(source);
    expect(source.allMatches(prompt), hasLength(1));
    expect(prompt.indexOf('Zadanie:'), greaterThan(prompt.indexOf(source)));
  });

  test('Attachment-only actions include an explicit task without inventing source text', () {
    final prompt = ChatTextAction.summarize.prompt('', hasAttachment: true);
    expect(prompt, contains('treść dołączonego pliku'));
    expect(prompt, contains('Zadanie: Streść'));
  });

  test(
    'Already translated text is requested unchanged rather than paraphrased',
    () {
      final prompt = ChatTextAction.translate.prompt('Źródło');
      expect(
        prompt,
        contains('Jeśli tekst jest już w języku docelowym, zwróć go bez zmian'),
      );
    },
  );
}
