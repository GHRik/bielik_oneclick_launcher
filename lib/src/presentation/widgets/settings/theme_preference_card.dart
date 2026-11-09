import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/app_theme_scope.dart';

class ThemePreferenceCard extends StatelessWidget {
  const ThemePreferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final effective = controller.preference == AppThemePreference.system
        ? Theme.of(context).brightness == Brightness.dark
              ? AppThemePreference.dark
              : AppThemePreference.light
        : controller.preference;

    Future<void> select(AppThemePreference value) async {
      try {
        await controller.select(value);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się zapisać motywu. Spróbuj ponownie.'),
            ),
          );
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wygląd aplikacji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final mode in [
                  AppThemePreference.light,
                  AppThemePreference.dark,
                ])
                  Semantics(
                    selected: effective == mode,
                    child: OutlinedButton.icon(
                      onPressed: controller.saving ? null : () => select(mode),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: effective == mode
                            ? colors.primaryContainer
                            : colors.surface,
                        foregroundColor: effective == mode
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                      ),
                      icon: Icon(
                        mode == AppThemePreference.light
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      label: Text(
                        mode == AppThemePreference.light ? 'Jasny' : 'Ciemny',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.preference == AppThemePreference.system
                  ? 'Motyw zgodny z ustawieniami systemu.'
                  : 'Wybrany motyw zapisuje się automatycznie.',
            ),
          ],
        ),
      ),
    );
  }
}
