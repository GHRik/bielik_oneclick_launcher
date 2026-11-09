import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class TextAttachmentPage extends StatelessWidget {
  const TextAttachmentPage({super.key, required this.attachment});
  final TextAttachment attachment;

  static void open(BuildContext context, TextAttachment attachment) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TextAttachmentPage(attachment: attachment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        attachment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectionArea(
          child: Text(
            attachment.text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ),
    ),
  );
}
