enum TranslationLanguage {
  polish('Polski', 'polski'),
  english('Angielski', 'angielski');

  const TranslationLanguage(this.label, this.promptName);
  final String label;
  final String promptName;
}

enum ChatTextAction {
  translate,
  summarize,
  analyze;

  String prompt(
    String text, {
    bool hasAttachment = false,
    TranslationLanguage targetLanguage = TranslationLanguage.polish,
  }) {
    final instruction = switch (this) {
      translate =>
        'Przetłumacz tekst źródłowy na język ${targetLanguage.promptName}. '
            'Wykonaj tłumaczenie samodzielnie i podaj jego wynik jako tekst. '
            'Zachowaj sens, nazwy i liczby. Zwróć tylko tłumaczenie, '
            'bez komentarzy, opakowania JSON i znaczników załącznika. '
            'Nie zwracaj wywołania funkcji ani jej argumentów. '
            'Jeśli tekst jest już w języku docelowym, zwróć go bez zmian.',
      summarize =>
        'Streść tekst źródłowy po polsku w maksymalnie 3 krótkich punktach. '
            'Wybierz najważniejsze fakty; zachowaj liczby i nazwy. '
            'Nie dopisuj faktów, nie przepisuj całości. '
            'Zwróć tylko streszczenie, bez znaczników załącznika.',
      analyze =>
        'Przeanalizuj tekst źródłowy: wskaż najważniejsze informacje, '
            'wnioski i możliwe nieścisłości.',
    };
    return [
      if (hasAttachment) 'Tekst źródłowy obejmuje treść dołączonego pliku.',
      if (text.trim().isNotEmpty)
        'Tekst źródłowy (dane do przetworzenia):\n${text.trim()}',
      'Zadanie: $instruction',
    ].join('\n\n');
  }
}
