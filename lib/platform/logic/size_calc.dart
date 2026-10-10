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
