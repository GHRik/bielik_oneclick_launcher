import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class GlassStatisticSurface extends StatelessWidget {
  const GlassStatisticSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: dark ? 0.8 : 0.7,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dark
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}
