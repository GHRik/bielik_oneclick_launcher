import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class ChatInputComposer extends StatefulWidget {
  const ChatInputComposer({
    super.key,
    required this.draft,
    required this.onSend,
    this.onAttachmentTap,
    this.onPasted,
    this.topWidget,
    this.sendDisabled = false,
    this.allowEmptyMessage = false,
    this.showSendButton = true,
    this.trailingPadding = 8,
  });

  final TextEditingController draft;
  final ValueChanged<String> onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onPasted;
  final Widget? topWidget;
  final bool sendDisabled;
  final bool allowEmptyMessage;
  final bool showSendButton;
  final double trailingPadding;

  @override
  State<ChatInputComposer> createState() => _ChatInputComposerState();
}

class _ChatInputComposerState extends State<ChatInputComposer> {
  final _contentKey = GlobalKey();
  bool _measureScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure();
  }

  @override
  void didUpdateWidget(ChatInputComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _measure();
  }

  void _measure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      context.read<ComposerHeightNotifier>().setHeight(
        box.size.height - MediaQuery.paddingOf(context).bottom,
      );
    });
  }

  bool get _canSend =>
      !widget.sendDisabled &&
      (widget.allowEmptyMessage || widget.draft.text.trim().isNotEmpty);

  void _send() {
    if (_canSend) widget.onSend(widget.draft.text.trim());
  }

  void _pasteError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nie udało się wkleić tekstu.')),
    );
  }

  Future<void> _paste() async {
    final draft = widget.draft;
    final before = draft.value;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted || draft != widget.draft || draft.value != before) return;
      final text = data?.text;
      if (text == null || text.isEmpty) return;
      final selection = before.selection.isValid
          ? before.selection
          : TextSelection.collapsed(offset: before.text.length);
      draft.value = before
          .replaced(selection, text)
          .copyWith(
            selection: TextSelection.collapsed(
              offset: selection.start + text.length,
            ),
            composing: TextRange.empty,
          );
      widget.onPasted?.call();
    } on PlatformException {
      _pasteError();
    }
  }

  Widget _contextMenu(BuildContext context, EditableTextState editable) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editable.contextMenuAnchors,
        buttonItems: [
          for (final item in editable.contextMenuButtonItems)
            item.kind == ContextMenuButtonKind.paste
                ? item.copyWith(
                    onPressed: () async {
                      final before = widget.draft.value;
                      try {
                        await editable.pasteText(SelectionChangedCause.toolbar);
                        if (mounted && widget.draft.value != before) {
                          widget.onPasted?.call();
                        }
                      } on PlatformException {
                        _pasteError();
                      }
                    },
                  )
                : item,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typography = ChatTheme.light().typography;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _measure();
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: ColoredBox(
            key: _contentKey,
            color: colors.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?widget.topWidget,
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8,
                    widget.trailingPadding,
                    8 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Row(
                    children: [
                      if (widget.onAttachmentTap != null)
                        IconButton(
                          tooltip: 'Dodaj plik TXT',
                          onPressed: widget.onAttachmentTap,
                          color: colors.primary,
                          icon: const Icon(
                            Icons.add,
                            semanticLabel: 'Dodaj plik TXT',
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Actions(
                          actions: {
                            PasteTextIntent: CallbackAction<PasteTextIntent>(
                              onInvoke: (_) => _paste(),
                            ),
                          },
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(
                                LogicalKeyboardKey.enter,
                                shift: true,
                              ): _send,
                            },
                            child: TextField(
                              controller: widget.draft,
                              minLines: 1,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              keyboardAppearance: theme.brightness,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _send(),
                              contextMenuBuilder: _contextMenu,
                              style: typography.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Napisz wiadomość…',
                                hintStyle: typography.bodyMedium.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: colors.surfaceContainerHighest,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.showSendButton)
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.draft,
                          builder: (context, _, _) => IconButton(
                            tooltip: 'Wyślij wiadomość',
                            onPressed: _canSend ? _send : null,
                            color: colors.primary,
                            icon: const Icon(
                              Icons.send,
                              semanticLabel: 'Wyślij wiadomość',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
