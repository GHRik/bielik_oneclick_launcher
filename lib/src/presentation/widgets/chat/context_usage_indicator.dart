import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';

class ContextUsageIndicator extends StatefulWidget {
  const ContextUsageIndicator({
    super.key,
    this.usage,
    this.showOmissionWarning = false,
    this.onOmissionsAcknowledged,
  });

  final ContextUsage? usage;
  final bool showOmissionWarning;
  final VoidCallback? onOmissionsAcknowledged;

  @override
  State<ContextUsageIndicator> createState() => _ContextUsageIndicatorState();
}

class _ContextUsageIndicatorState extends State<ContextUsageIndicator>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2700),
  );
  String? _animatedOmissions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePulse();
  }

  @override
  void didUpdateWidget(ContextUsageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    if (!widget.showOmissionWarning ||
        MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
      return;
    }
    final signature = widget.usage?.omittedMessageIds.join('\n');
    if (signature != _animatedOmissions) {
      _animatedOmissions = signature;
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _showDetails() {
    final value = widget.usage;
    widget.onOmissionsAcknowledged?.call();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kontekst tej rozmowy'),
        content: SingleChildScrollView(
          child: Text(
            value == null
                ? 'Pomiar pojawi się po przygotowaniu pierwszej wiadomości przez model. '
                      'Obejmuje również instrukcję systemową Bielika.'
                : [
                    '${value.usedTokens} / ${value.contextSize} tokenów (${value.percent}%).',
                    'Wejście: ${value.promptTokens}. Odpowiedź: ${value.responseTokens}.',
                    if (value.hasOmittedHistory) ...[
                      'Pominięte wiadomości: ${value.omittedMessageIds.length}. '
                          'Część wcześniejszej rozmowy nie została przekazana do modelu '
                          'z powodu limitu kontekstu. Wiadomości nadal są zapisane w czacie.',
                      if (value.omittedAttachmentNames.isNotEmpty)
                        'Załączniki w pominiętych wiadomościach:\n'
                            '${value.omittedAttachmentNames.map((name) => '• $name').join('\n')}',
                      'Model może nie mieć informacji potrzebnych do odpowiedzi. '
                          'Jeśli pytasz o pominięty tekst lub plik, dodaj go ponownie.',
                    ],
                    'Ostatni pomiar dla tej rozmowy. Uwzględnia instrukcję systemową '
                        'i historię przekazaną do modelu. Wynik aktualizuje się przed '
                        'generowaniem i po odpowiedzi. Szkic nie jest uwzględniony. '
                        'Gdy brakuje miejsca, najstarsze wymiany wypadają z kontekstu.',
                  ].join('\n\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.usage;
    final label = value == null
        ? 'Kontekst: brak pomiaru'
        : 'Kontekst: ${value.percent}% · ${value.usedTokens}/${value.contextSize} tokenów';
    final scheme = Theme.of(context).colorScheme;
    const warningColor = Color(0xFFFFB300);
    final color = widget.showOmissionWarning
        ? warningColor
        : value != null && value.fraction >= 0.9
        ? scheme.error
        : scheme.primary;
    return IconButton(
      tooltip: widget.showOmissionWarning
          ? '$label · Część historii poza kontekstem'
          : label,
      onPressed: _showDetails,
      icon: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.12 * math.sin(_pulse.value * math.pi * 6).abs(),
          child: child,
        ),
        child: SizedBox.square(
          dimension: 32,
          child: Stack(
            clipBehavior: Clip.none,
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
              if (widget.showOmissionWarning)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    key: const ValueKey('context-omission-warning'),
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: warningColor,
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
