import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onRemove,
    this.onOpen,
    this.removable = true,
  });
  final TextAttachment attachment;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  final bool removable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Otwórz załącznik ${attachment.name}',
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
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
                      attachment.sizeBytes < 1024
                          ? '${attachment.sizeBytes} B'
                          : '${(attachment.sizeBytes / 1024).toStringAsFixed(1)} KiB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (removable)
          IconButton(
            tooltip: 'Usuń załącznik',
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20),
          ),
      ],
    ),
  );
}
