// Модель состояния записи (Dart). Зеркало Kotlin RecorderState и контракта каналов v1.
sealed class RecorderState {
  const RecorderState();

  factory RecorderState.fromMap(Map<Object?, Object?> m) {
    switch (m['type']) {
      case 'idle':
        return const Idle();
      case 'countdown':
        return Countdown((m['secondsLeft'] as num?)?.toInt() ?? 0);
      case 'starting':
        return const Starting();
      case 'recording':
        return Recording(
          Duration(milliseconds: (m['elapsedMs'] as num?)?.toInt() ?? 0),
        );
      case 'paused':
        return Paused(
          Duration(milliseconds: (m['elapsedMs'] as num?)?.toInt() ?? 0),
        );
      case 'saving':
        return const Saving();
      case 'failed':
        return Failed(
          (m['code'] as String?) ?? 'unknown',
          m['message'] as String?,
        );
      case 'saved':
        return Saved(
          uri: (m['uri'] as String?) ?? '',
          duration: Duration(
            milliseconds: (m['durationMs'] as num?)?.toInt() ?? 0,
          ),
          sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
        );
      default:
        return const Idle();
    }
  }

  Map<String, Object?> toMap() => switch (this) {
    Idle() => {'type': 'idle'},
    Countdown(secondsLeft: final s) => {'type': 'countdown', 'secondsLeft': s},
    Starting() => {'type': 'starting'},
    Recording(elapsed: final e) => {
      'type': 'recording',
      'elapsedMs': e.inMilliseconds,
    },
    Paused(elapsed: final e) => {
      'type': 'paused',
      'elapsedMs': e.inMilliseconds,
    },
    Saving() => {'type': 'saving'},
    Failed(code: final c, message: final msg) => {
      'type': 'failed',
      'code': c,
      // ignore: use_null_aware_elements
      if (msg != null) 'message': msg,
    },
    Saved(uri: final u, duration: final d, sizeBytes: final s) => {
      'type': 'saved',
      'uri': u,
      'durationMs': d.inMilliseconds,
      'sizeBytes': s,
    },
  };
}

class Idle extends RecorderState {
  const Idle();
}

class Countdown extends RecorderState {
  const Countdown(this.secondsLeft);
  final int secondsLeft;
}

class Starting extends RecorderState {
  const Starting();
}

class Recording extends RecorderState {
  const Recording(this.elapsed);
  final Duration elapsed;
}

class Paused extends RecorderState {
  const Paused(this.elapsed);
  final Duration elapsed;
}

class Saving extends RecorderState {
  const Saving();
}

class Failed extends RecorderState {
  const Failed(this.code, [this.message]);
  final String code;
  final String? message;
}

/// Одноразовое событие «сохранено», после него приходит idle.
class Saved extends RecorderState {
  const Saved({
    required this.uri,
    required this.duration,
    required this.sizeBytes,
  });
  final String uri;
  final Duration duration;
  final int sizeBytes;
}
