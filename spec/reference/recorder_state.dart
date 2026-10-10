// Модель состояния записи (Dart). Зеркало Kotlin RecorderState и контракта каналов.
sealed class RecorderState {
  const RecorderState();

  factory RecorderState.fromMap(Map<Object?, Object?> m) {
    switch (m['type']) {
      case 'idle':
        return const Idle();
      case 'countdown':
        return Countdown(m['secondsLeft'] as int);
      case 'starting':
        return const Starting();
      case 'recording':
        return Recording(Duration(milliseconds: m['elapsedMs'] as int));
      case 'paused':
        return Paused(Duration(milliseconds: m['elapsedMs'] as int));
      case 'saving':
        return const Saving();
      case 'failed':
        return Failed(m['code'] as String, m['message'] as String?);
      default:
        return const Idle();
    }
  }
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
