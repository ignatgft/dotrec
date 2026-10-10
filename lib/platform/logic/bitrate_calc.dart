/// Битрейт по умолчанию: w*h*fps*k, затем ближайшее из списка.
/// k = 0.07 для H.264, 0.045 для HEVC (см. docs/04).
abstract final class BitrateCalc {
  static const List<int> stepsMbps = [4, 8, 12, 20, 40];

  static int defaultMbps({
    required int width,
    required int height,
    required int fps,
    required bool hevc,
  }) {
    final double k = hevc ? 0.045 : 0.07;
    final double mbps = width * height * fps * k / 1000000.0;
    int best = stepsMbps.first;
    double bestDist = (best - mbps).abs();
    for (final s in stepsMbps.skip(1)) {
      final double d = (s - mbps).abs();
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return best;
  }
}
