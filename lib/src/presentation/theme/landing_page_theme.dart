import 'package:material_ui/material_ui.dart';

ThemeData landingPageTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? const Color(0xff151613) : const Color(0xfff5f2e9);
  final ink = dark ? const Color(0xffeeeadd) : const Color(0xff26291f);
  final muted = dark ? const Color(0xffb2b1a2) : const Color(0xff555a49);
  final accent = dark ? const Color(0xffb8c8a0) : const Color(0xff964811);
  final surface = dark ? const Color(0xff1c211a) : const Color(0xfffffdf6);
  final soft = dark ? const Color(0xff293225) : const Color(0xffebe8db);
  final line = dark ? const Color(0xff353c30) : const Color(0xffd8d7c9);
  final strongLine = dark ? const Color(0xff68765d) : const Color(0xff767c67);
  final onAccent = dark ? const Color(0xff181a14) : const Color(0xfffffdf6);
  final colors = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: soft,
        onPrimaryContainer: ink,
        secondary: accent,
        onSecondary: onAccent,
        secondaryContainer: soft,
        onSecondaryContainer: ink,
        surface: paper,
        onSurface: ink,
        onSurfaceVariant: muted,
        surfaceContainerLowest: paper,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: soft,
        surfaceContainerHighest: soft,
        outline: strongLine,
        outlineVariant: line,
        surfaceTint: Colors.transparent,
      );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: paper,
    canvasColor: surface,
    dividerColor: line,
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accent,
      selectionColor: accent.withValues(alpha: 0.25),
      selectionHandleColor: accent,
    ),
  );
}
