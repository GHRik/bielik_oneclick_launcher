import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/app_theme_scope.dart';

class ThemePreferenceCard extends StatelessWidget {
  const ThemePreferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
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
            DropdownButtonFormField<AppThemePreference>(
              key: ValueKey(controller.preference),
              initialValue: controller.preference,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Motyw',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: AppThemePreference.system,
                  child: Text('Systemowy'),
                ),
                DropdownMenuItem(
                  value: AppThemePreference.light,
                  child: Text('Jasny'),
                ),
                DropdownMenuItem(
                  value: AppThemePreference.dark,
                  child: Text('Ciemny'),
                ),
              ],
              onChanged: controller.saving
                  ? null
                  : (value) async {
                      if (value == null) return;
                      try {
                        await controller.select(value);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nie udało się zapisać motywu. Spróbuj ponownie.',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 8),
            const Text('Zmiana działa od razu i zapisuje się automatycznie.'),
          ],
        ),
      ),
    );
  }
}
