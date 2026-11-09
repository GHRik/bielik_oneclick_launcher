import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.attachment, this.onRemove});
  final TextAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            attachment.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(attachment.sizeBytes / 1024).toStringAsFixed(1)} KiB',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        IconButton(
          tooltip: 'Usuń załącznik',
          onPressed: onRemove,
          icon: const Icon(Icons.close, size: 20),
        ),
      ],
    ),
  );
}
