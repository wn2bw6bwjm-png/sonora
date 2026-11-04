import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static const _serif = 'Newsreader';
  static const _sans = 'Inter';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        accent: SonoraColors.accentLight,
        bg: SonoraColors.bgLight,
        surface: SonoraColors.surfaceLight,
        ink: SonoraColors.inkLight,
        muted: SonoraColors.mutedLight,
        line: SonoraColors.lineLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        accent: SonoraColors.accentDark,
        bg: SonoraColors.bgDark,
        surface: SonoraColors.surfaceDark,
        ink: SonoraColors.inkDark,
        muted: SonoraColors.mutedDark,
        line: SonoraColors.lineDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
  }) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isLight ? Colors.white : bg,
      secondary: accent,
      onSecondary: isLight ? Colors.white : bg,
      error: const Color(0xFFC0392B),
      onError: Colors.white,
      surface: bg,
      onSurface: ink,
      surfaceContainerHighest: surface,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
    );

    TextStyle sans(double size, FontWeight w, {Color? c, double? h, double ls = 0}) =>
        TextStyle(fontFamily: _sans, fontSize: size, fontWeight: w, color: c ?? ink, height: h, letterSpacing: ls);
    TextStyle serif(double size) => TextStyle(
        fontFamily: _serif, fontSize: size, fontWeight: FontWeight.w500, color: ink, height: 1.15, letterSpacing: -0.3);

    final text = TextTheme(
      displaySmall: serif(36),
      headlineMedium: serif(28),
      headlineSmall: serif(22),
      titleLarge: serif(20),
      titleMedium: sans(16, FontWeight.w600, h: 1.3),
      titleSmall: sans(14, FontWeight.w600, h: 1.3),
      bodyLarge: sans(16, FontWeight.w400, h: 1.5),
      bodyMedium: sans(14, FontWeight.w400, h: 1.5),
      bodySmall: sans(12, FontWeight.w400, c: muted, h: 1.4),
      labelLarge: sans(14, FontWeight.w600),
      labelMedium: sans(12, FontWeight.w500, c: muted, ls: 0.2),
      labelSmall: sans(11, FontWeight.w600, c: muted, ls: 0.8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: serif(20),
        iconTheme: IconThemeData(color: ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            sans(11, FontWeight.w600, c: s.contains(WidgetState.selected) ? ink : muted)),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? accent : muted)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: Rad.mdAll)),
          side: WidgetStatePropertyAll(BorderSide(color: line)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
