import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_theme_repository.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController({
    AppThemePreference initial = AppThemePreference.system,
    this.repository,
  }) : preference = initial;

  final AppThemeRepository? repository;
  AppThemePreference preference;
  bool saving = false;
  bool _disposed = false;

  ThemeMode get mode => switch (preference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  Future<void> select(AppThemePreference next) async {
    if (saving || next == preference) return;
    final previous = preference;
    preference = next;
    saving = true;
    notifyListeners();
    try {
      await repository?.save(next);
    } catch (_) {
      preference = previous;
      rethrow;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
