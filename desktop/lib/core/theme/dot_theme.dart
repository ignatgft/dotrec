import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class DotTheme {
  static ThemeData dark() {
    const DotColors c = DotColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.dark(
        surface: c.surface,
        onSurface: c.fg,
        primary: c.fg,
        onPrimary: c.bg,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DotTokens.radiusCard),
          side: BorderSide(color: c.line, width: 1),
        ),
      ),
      extensions: const [c],
    );
  }

  static ThemeData light() {
    const DotColors c = DotColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.light(
        surface: c.surface,
        onSurface: c.fg,
        primary: c.fg,
        onPrimary: c.bg,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DotTokens.radiusCard),
          side: BorderSide(color: c.line, width: 1),
        ),
      ),
      extensions: const [c],
    );
  }
}
