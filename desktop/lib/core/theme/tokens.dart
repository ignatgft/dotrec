import 'package:flutter/material.dart';

abstract final class DotTokens {
  // Радиусы
  static const double radiusChip = 12;
  static const double radiusCard = 16;
  static const double radiusButton = 12;

  // Отступы
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Типографика
  static const String dotFamily = 'Doto';

  // Фирменный красный акцент для REC и эфира
  static const Color accentRed = Color(0xFFD71921);
}

@immutable
class DotColors extends ThemeExtension<DotColors> {
  const DotColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.fg,
    required this.fgMuted,
    required this.record,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color fg;
  final Color fgMuted;
  final Color record;

  static const DotColors dark = DotColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF151515),
    surfaceRaised: Color(0xFF1F1F1F),
    line: Color(0xFF2B2B2B),
    fg: Color(0xFFFFFFFF),
    fgMuted: Color(0xFF8C8C8C),
    record: DotTokens.accentRed,
  );

  static const DotColors light = DotColors(
    bg: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEBEBEF),
    line: Color(0xFFE0E0E6),
    fg: Color(0xFF000000),
    fgMuted: Color(0xFF6B6B76),
    record: DotTokens.accentRed,
  );

  @override
  DotColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? fg,
    Color? fgMuted,
    Color? record,
  }) {
    return DotColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      fg: fg ?? this.fg,
      fgMuted: fgMuted ?? this.fgMuted,
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
      record: Color.lerp(record, other.record, t)!,
    );
  }
}

extension DotContext on BuildContext {
  DotColors get dot =>
      Theme.of(this).extension<DotColors>() ?? DotColors.dark;
}
