import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/math_markdown.dart';
import 'package:material_ui/material_ui.dart';

class AssistantMarkdownMessage extends StatelessWidget {
  const AssistantMarkdownMessage({super.key, required this.message});

  final TextMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.5,
    );
    return SelectionArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: message.text,
                inlineSyntaxes: [MathInlineSyntax()],
                extensionSet: md.ExtensionSet.gitHubFlavored,
                builders: {'math': MathElementBuilder(textStyle)},
                fitContent: true,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet(
                  p: textStyle,
                  a: TextStyle(color: theme.colorScheme.primary),
                  listBullet: textStyle,
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  em: const TextStyle(fontStyle: FontStyle.italic),
                  code: textStyle.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  h1: textStyle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: textStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                imageBuilder: (uri, title, alt) => Text(
                  alt?.isNotEmpty == true ? alt! : uri.toString(),
                  style: textStyle,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TimeAndStatus(
                  time: message.resolvedTime,
                  showStatus: false,
                  textStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
