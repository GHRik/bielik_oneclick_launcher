enum ChatTextAction {
  translate,
  summarize,
  analyze;

  String prompt(String text, {bool hasAttachment = false}) {
    final instruction = switch (this) {
      translate => 'Przetłumacz poniższą treść na język polski.',
      summarize =>
        'Streść poniższą treść, zachowując najważniejsze informacje.',
      analyze => 'Przeanalizuj poniższą treść: wskaż najważniejsze informacje, wnioski i możliwe nieścisłości.',
    };
    final attachment = hasAttachment
        ? '\nUwzględnij treść dołączonego pliku.'
        : '';
    final content = text.trim();
    return '$instruction$attachment${content.isEmpty ? "" : "\n\n$content"}';
  }
}
