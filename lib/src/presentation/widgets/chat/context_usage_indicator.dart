import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';

class ContextUsageIndicator extends StatelessWidget {
  const ContextUsageIndicator({super.key, this.usage});

  final ContextUsage? usage;

  @override
  Widget build(BuildContext context) {
    final value = usage;
    final label = value == null
        ? 'Kontekst: brak pomiaru'
        : 'Kontekst: ${value.percent}% · ${value.usedTokens}/${value.contextSize} tokenów';
    final scheme = Theme.of(context).colorScheme;
    final color = value != null && value.fraction >= 0.9
        ? scheme.error
        : scheme.primary;
    return IconButton(
      tooltip: label,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kontekst tej rozmowy'),
          content: Text(
            value == null
                ? 'Pomiar pojawi się po przygotowaniu pierwszej wiadomości przez model. '
                      'Obejmuje również instrukcję systemową Bielika.'
                : '${value.usedTokens} / ${value.contextSize} tokenów (${value.percent}%).\n\n'
                      'Wejście: ${value.promptTokens}. Odpowiedź: ${value.responseTokens}.\n\n'
                      'Ostatni pomiar dla tej rozmowy. Uwzględnia instrukcję systemową '
                      'i historię przekazaną do modelu. Wynik aktualizuje się przed '
                      'generowaniem i po odpowiedzi. Szkic nie jest uwzględniony. '
                      'Gdy brakuje miejsca, najstarsze wymiany wypadają z kontekstu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      ),
      icon: SizedBox.square(
        dimension: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value?.fraction ?? 0,
                strokeWidth: 3,
                color: color,
                backgroundColor: scheme.outlineVariant,
              ),
            ),
            Text(
              value == null ? '—' : '${value.percent}%',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
