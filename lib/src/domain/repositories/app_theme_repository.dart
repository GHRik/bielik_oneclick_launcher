import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';

abstract interface class AppThemeRepository {
  Future<AppThemePreference> load();
  Future<void> save(AppThemePreference preference);
}
