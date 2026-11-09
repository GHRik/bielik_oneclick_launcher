import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_input_composer.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';

class DictationComposer extends StatelessWidget {
  const DictationComposer({
    super.key,
    required this.draft,
    required this.dictation,
    required this.onMicrophoneTap,
    required this.sending,
    required this.onSend,
    this.attachmentPreview,
    this.quickActions,
    this.onAttachmentTap,
    this.onPasted,
    this.allowEmptyMessage = false,
    this.showAttachmentButton = false,
  });

  final TextEditingController draft;
  final SpeechDictationController? dictation;
  final VoidCallback? onMicrophoneTap;
  final bool sending;
  final ValueChanged<String> onSend;
  final Widget? attachmentPreview;
  final Widget? quickActions;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onPasted;
  final bool allowEmptyMessage;
  final bool showAttachmentButton;

  @override
  Widget build(BuildContext context) {
    final speech = dictation;
    final composer = ChatInputComposer(
      draft: draft,
      onSend: onSend,
      onAttachmentTap: showAttachmentButton ? onAttachmentTap : null,
      onPasted: onPasted,
      allowEmptyMessage: allowEmptyMessage,
      sendDisabled: sending || (speech?.active ?? false),
      showSendButton: speech == null,
      trailingPadding: speech == null ? 8 : 112,
      topWidget:
          quickActions != null ||
              attachmentPreview != null ||
              speech?.error != null ||
              speech?.active == true
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?quickActions,
                ?attachmentPreview,
                if (speech?.error != null || speech?.active == true)
                  Padding(
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
                  ),
              ],
            )
          : null,
    );
    if (speech == null) return composer;
    return Stack(
      fit: StackFit.expand,
      children: [
        composer,
        Positioned(
          right: 64,
          bottom: MediaQuery.paddingOf(context).bottom + 8,
          child: IconButton(
            tooltip: speech.active
                ? 'Zatrzymaj dyktowanie'
                : 'Dyktuj wiadomość',
            isSelected: speech.active,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: sending || speech.finishing ? null : onMicrophoneTap,
            icon: const Icon(Icons.mic_none),
            selectedIcon: const Icon(Icons.mic),
          ),
        ),
        Positioned(
          right: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 8,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: draft,
            builder: (context, value, _) => IconButton(
              tooltip: 'Wyślij wiadomość',
              color: Theme.of(context).colorScheme.primary,
              onPressed:
                  sending ||
                      speech.active ||
                      (value.text.trim().isEmpty && !allowEmptyMessage)
                  ? null
                  : () => onSend(value.text.trim()),
              icon: const Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
            ),
          ),
        ),
      ],
    );
  }
}
