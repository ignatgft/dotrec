/// Элемент библиотеки (контракт v1).
class RecordingItem {
  const RecordingItem({
    required this.uri,
    required this.name,
    required this.duration,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String uri;
  final String name;
  final Duration duration;
  final int sizeBytes;
  final DateTime createdAt;

  factory RecordingItem.fromMap(Map<Object?, Object?> m) {
    return RecordingItem(
      uri: (m['uri'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      duration: Duration(milliseconds: (m['durationMs'] as num?)?.toInt() ?? 0),
      sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (m['createdAtMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, Object?> toMap() => {
    'uri': uri,
    'name': name,
    'durationMs': duration.inMilliseconds,
    'sizeBytes': sizeBytes,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
  };
}
