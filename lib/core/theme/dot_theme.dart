import 'package:flutter/material.dart';

import 'tokens.dart';

/// Сборка ThemeData из токенов. Material 3 включён, компоненты переопределены.
/// Красный record — только для записи, ColorScheme собирается вручную (без fromSeed).
abstract final class DotTheme {
  static ThemeData light() => _build(DotColors.light, Brightness.light);

  static ThemeData dark() => _build(DotColors.dark, Brightness.dark);

  static ThemeData _build(DotColors dot, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: dot.fg,
      onPrimary: dot.onFg,
      secondary: dot.fgMuted,
      onSecondary: dot.onFg,
      error: dot.fg,
      onError: dot.onFg,
      surface: dot.surface,
      onSurface: dot.fg,
      surfaceContainerHighest: dot.surfaceRaised,
      outline: dot.line,
      tertiary: dot.record,
      onTertiary: const Color(0xFFFFFFFF),
      primaryContainer: dot.surfaceRaised,
      onPrimaryContainer: dot.fg,
      secondaryContainer: dot.surface,
      onSecondaryContainer: dot.fgMuted,
      errorContainer: dot.surface,
      onErrorContainer: dot.fg,
      tertiaryContainer: dot.record,
      onTertiaryContainer: const Color(0xFFFFFFFF),
      surfaceContainer: dot.surface,
      surfaceTint: Colors.transparent,
    );

    // Точечный шрифт — только таймер/статус/числа/заголовки (см. docs/05).
    const TextStyle dotStyle = TextStyle(fontFamily: DotTokens.dotFamily);
    final TextTheme text =
        (isDark
                ? ThemeData.dark(useMaterial3: true).textTheme
                : ThemeData.light(useMaterial3: true).textTheme)
            .copyWith(
              displayLarge: dotStyle.copyWith(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: dot.fg,
                letterSpacing: 1.5,
              ),
              titleLarge: dotStyle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: dot.fg,
                letterSpacing: 0.5,
              ),
              titleMedium: dotStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dot.fg,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: dot.fg,
              ),
              bodyMedium: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dot.fg,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: dot.fgMuted,
              ),
              labelSmall: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: dot.fgMuted,
              ),
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dot.bg,
      canvasColor: dot.bg,
      extensions: <ThemeExtension<dynamic>>[dot],
      textTheme: text,
      dividerTheme: DividerThemeData(color: dot.line, thickness: 0.5),
      cardTheme: CardThemeData(
        color: dot.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DotTokens.radiusCard),
          side: BorderSide(color: dot.line, width: DotTokens.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: dot.fg,
        disabledColor: Colors.transparent,
        labelStyle: TextStyle(color: dot.fg, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DotTokens.radiusChip),
          side: BorderSide(color: dot.line, width: DotTokens.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dot.fg,
          foregroundColor: dot.onFg,
          minimumSize: const Size(48, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DotTokens.radiusTile),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(DotTokens.touchMin, DotTokens.touchMin),
          iconSize: DotTokens.icon,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? dot.onFg : dot.fgMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? dot.fg : dot.line,
        ),
        trackOutlineColor: WidgetStatePropertyAll(dot.line),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: dot.fg,
        inactiveTrackColor: dot.line,
        thumbColor: dot.fg,
        overlayColor: dot.fg.withValues(alpha: 0.12),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(48, DotTokens.touchMin),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DotTokens.radiusChip),
            ),
          ),
        ),
      ),
    );
  }
}
