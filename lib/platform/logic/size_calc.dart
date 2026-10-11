/// Подбор размеров видео: масштаб по короткой стороне, обе стороны чётные.
/// Если экран меньше целевого — такой пункт скрывается (см. docs/04).
abstract final class SizeCalc {
  /// Возвращает (w, h) или null, если экран меньше целевого.
  static (int, int)? fit({
    required int screenW,
    required int screenH,
    required int targetShortSide,
  }) {
    final int shortSide = screenW < screenH ? screenW : screenH;
    if (shortSide < targetShortSide) return null;
    final double scale = targetShortSide / shortSide;
    int w = (screenW * scale).round();
    int h = (screenH * scale).round();
    // Обе стороны чётные (энкодеры требуют кратных 2).
    w -= w % 2;
    h -= h % 2;
    if (w < 2 || h < 2) return null;
    return (w, h);
  }

  static List<int> availableTargets({
    required int screenW,
    required int screenH,
  }) {
    const List<int> all = [720, 1080, 1440];
    return [
      for (final t in all)
        if (fit(screenW: screenW, screenH: screenH, targetShortSide: t) != null)
          t,
    ];
  }
}

/// Оценка размера файла перед записью (docs/11).
abstract final class FileSizeEstimator {
  /// Оценка размера в мегабайтах за указанную продолжительность.
  static double estimateMb({
    required int bitrateMbps,
    int durationSeconds = 60,
  }) {
    return (bitrateMbps * durationSeconds) / 8.0;
  }

  /// Читаемая строка для UI: «~90 МБ / мин».
  static String estimatePerMinute(int bitrateMbps) {
    final int mb = estimateMb(bitrateMbps: bitrateMbps, durationSeconds: 60).round();
    return '~$mb МБ / мин';
  }
}
