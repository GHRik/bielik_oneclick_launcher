import 'package:material_ui/material_ui.dart';

class ChatModelHeader extends StatelessWidget {
  const ChatModelHeader({
    super.key,
    required this.status,
    required this.modelName,
  });

  final String status;
  final String modelName;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '$modelName\n$status',
    child: LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 48,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
