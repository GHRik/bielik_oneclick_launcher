import 'package:material_ui/material_ui.dart';

class MessageCopyButton extends StatefulWidget {
  const MessageCopyButton({super.key, this.onCopy});

  final Future<void> Function()? onCopy;

  @override
  State<MessageCopyButton> createState() => _MessageCopyButtonState();
}

class _MessageCopyButtonState extends State<MessageCopyButton> {
  bool _copying = false;

  Future<void> _copy() async {
    final copy = widget.onCopy;
    if (copy == null || _copying) return;
    setState(() => _copying = true);
    try {
      await copy();
    } catch (_) {
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          const SnackBar(content: Text('Nie udało się skopiować wiadomości.')),
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Kopiuj całą wiadomość',
    onPressed: widget.onCopy == null || _copying ? null : _copy,
    icon: const Icon(Icons.copy_outlined, size: 18),
  );
}
