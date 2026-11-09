import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_theme_preference.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_theme_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/settings/theme_preference_card.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class MemoryThemeRepository implements AppThemeRepository {
  AppThemePreference saved = AppThemePreference.system;
  bool fail = false;

  @override
  Future<AppThemePreference> load() async => saved;

  @override
  Future<void> save(AppThemePreference preference) async {
    if (fail) throw StateError('Cannot save');
    saved = preference;
  }
}

Future<void> openApp(
  WidgetTester tester, {
  AppThemePreference initial = AppThemePreference.system,
  AppThemeRepository? repository,
}) async {
  await tester.pumpWidget(
    MyApp(
      themePreference: initial,
      themeRepository: repository,
      chatRepository: InMemoryChatRepository(),
      modelFilesRepository: InMemoryModelFilesRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Brightness brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

Future<void> choose(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<AppThemePreference>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('The default theme follows system brightness changes', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openApp(tester);
    expect(brightness(tester), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('A saved light preference overrides a dark system', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openApp(tester, initial: AppThemePreference.light);
    expect(brightness(tester), Brightness.light);
  });

  testWidgets('Appearance is the first settings section', (tester) async {
    await openApp(tester);
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemePreferenceCard), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Wygląd aplikacji')).dy,
      lessThan(tester.getTopLeft(find.text('Kontekst i odpowiedź')).dy),
    );
  });

  testWidgets(
    'Changing the theme updates the open settings page and saves it',
    (tester) async {
      final repository = MemoryThemeRepository();
      await openApp(tester, repository: repository);
      await tester.tap(find.byTooltip('Konfiguracja LLM'));
      await tester.pumpAndSettle();
      await choose(tester, 'Ciemny');
      expect(brightness(tester), Brightness.dark);
      expect(repository.saved, AppThemePreference.dark);
      expect(find.text('Konfiguracja LLM'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
    },
  );

  testWidgets('A failed save restores the previous theme', (tester) async {
    final repository = MemoryThemeRepository()..fail = true;
    await openApp(
      tester,
      initial: AppThemePreference.light,
      repository: repository,
    );
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    await choose(tester, 'Ciemny');
    expect(brightness(tester), Brightness.light);
    expect(
      find.text('Nie udało się zapisać motywu. Spróbuj ponownie.'),
      findsOneWidget,
    );
  });
}
