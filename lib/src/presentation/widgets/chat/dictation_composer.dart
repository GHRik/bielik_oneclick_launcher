import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';

class DictationComposer extends StatelessWidget {
  const DictationComposer({
    super.key,
    required this.draft,
    required this.dictation,
    required this.onMicrophoneTap,
    required this.sending,
  });

  final TextEditingController draft;
  final SpeechDictationController? dictation;
  final VoidCallback? onMicrophoneTap;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final speech = dictation;
    final composer = Composer(
      textEditingController: draft,
      hintText: 'Napisz wiadomość…',
      attachmentIcon: null,
      inputClearMode: InputClearMode.never,
      sendButtonDisabled: sending || (speech?.active ?? false),
      sendIcon: const Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
      right: speech == null ? 0 : 56,
      topWidget: speech?.error != null || speech?.active == true
          ? Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  speech!.error ??
                      (speech.starting
                          ? 'Uruchamianie mikrofonu…'
                          : speech.finishing
                          ? 'Kończenie dyktowania…'
                          : 'Słucham… Kliknij mikrofon, aby zakończyć.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          : null,
    );
    if (speech == null) return composer;
    return Stack(
      fit: StackFit.expand,
      children: [
        composer,
        Positioned(
          right: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 8,
          child: IconButton(
            tooltip: speech.active
                ? 'Zatrzymaj dyktowanie'
                : 'Dyktuj wiadomość',
            isSelected: speech.active,
            onPressed: sending || speech.finishing ? null : onMicrophoneTap,
            icon: const Icon(Icons.mic_none),
            selectedIcon: const Icon(Icons.mic),
          ),
        ),
      ],
    );
  }
}
