import 'package:material_ui/material_ui.dart';

class MessageCopyButton extends StatelessWidget {
  const MessageCopyButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.copy_outlined, size: 18),
    label: const Text('Kopiuj'),
  );
}
