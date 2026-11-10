import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';

class TranslationLanguageDialog extends StatelessWidget {
  const TranslationLanguageDialog({super.key});

  @override
  Widget build(BuildContext context) => SimpleDialog(
    title: const Text('Na jaki język przetłumaczyć?'),
    children: [
      for (final language in TranslationLanguage.values)
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(language),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(language.label),
        ),
      SimpleDialogOption(
        onPressed: () => Navigator.of(context).pop(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: const Text('Anuluj'),
      ),
    ],
  );
}
