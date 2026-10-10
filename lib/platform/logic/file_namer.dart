/// Имена файлов: DotRec_YYYYMMDD_HHmmss.mp4 (см. FR-REC-08).
abstract final class FileNamer {
  static String name(DateTime at) {
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return 'DotRec_${at.year}${p(at.month)}${p(at.day)}_${p(at.hour)}${p(at.minute)}${p(at.second)}.mp4';
  }

  static final RegExp pattern = RegExp(r'^DotRec_\d{8}_\d{6}\.mp4$');
}
