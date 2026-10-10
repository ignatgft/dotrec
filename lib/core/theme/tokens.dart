import 'package:flutter/material.dart';

/// Дизайн-токены DotRec (зеркало design/tokens.json v1.0.0).
abstract final class DotTokens {
  // Радиусы
  static const double radiusChip = 12;
  static const double radiusCard = 20;
  static const double radiusTile = 28;
  static const double radiusPill = 999;

  // Отступы
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Обводки
  static const double hairline = 0.5;
  static const double ring = 2;

  // Размеры
  static const double recordButton = 120;
  static const double recordInner = 72;
  static const double recordStop = 44;
  static const double touchMin = 48;
  static const double icon = 24;

  // Типографика
  static const String dotFamily = 'Doto';

  // Анимации
  static const int recordMorphMs = 220;
  static const int pulseMs = 2000;
  static const int chipSelectMs = 120;

  // Пресеты
  static const Map<String, (int res, int fps, int bitrate)> presets = {
    'fast': (720, 30, 6),
    'balanced': (1080, 60, 20),
    'quality': (1440, 60, 40),
  };

  static const List<int> resolutions = [720, 1080, 1440];
  static const List<int> fpsOptions = [30, 60, 90];
  static const List<int> bitrates = [4, 8, 12, 20, 40];
  static const List<int> countdownOptions = [0, 3, 5];
}

/// Цвета DotRec для одной темы.
@immutable
class DotColors extends ThemeExtension<DotColors> {
  const DotColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.fg,
    required this.fgMuted,
    required this.onFg,
    required this.record,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color fg;
  final Color fgMuted;
  final Color onFg;
  final Color record;

  static const DotColors dark = DotColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF151515),
    surfaceRaised: Color(0xFF1F1F1F),
    line: Color(0xFF2B2B2B),
    fg: Color(0xFFFFFFFF),
    fgMuted: Color(0xFF8C8C8C),
    onFg: Color(0xFF000000),
    record: Color(0xFFD71921),
  );

  static const DotColors light = DotColors(
    bg: Color(0xFFF1F1F1),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    line: Color(0xFFDCDCDC),
    fg: Color(0xFF101010),
    fgMuted: Color(0xFF6B6B6B),
    onFg: Color(0xFFFFFFFF),
    record: Color(0xFFD71921),
  );

  @override
  DotColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? fg,
    Color? fgMuted,
    Color? onFg,
    Color? record,
  }) {
    return DotColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      fg: fg ?? this.fg,
      fgMuted: fgMuted ?? this.fgMuted,
      onFg: onFg ?? this.onFg,
      record: record ?? this.record,
    );
  }

  @override
  DotColors lerp(ThemeExtension<DotColors>? other, double t) {
    if (other is! DotColors) return this;
    return DotColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      onFg: Color.lerp(onFg, other.onFg, t)!,
      record: Color.lerp(record, other.record, t)!,
    );
  }
}

extension DotColorsOf on BuildContext {
  DotColors get dot => Theme.of(this).extension<DotColors>()!;
}
