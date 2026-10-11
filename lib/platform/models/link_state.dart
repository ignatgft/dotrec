class LinkState {
  const LinkState({
    this.status = 'idle',
    this.mode = 'usb',
    this.pin = '',
    this.pinTtlSec = 0,
    this.clientName = '',
    this.streamActive = false,
    this.latencyMs = 24,
  });

  final String status; // 'idle', 'listening', 'connected', 'streaming'
  final String mode; // 'usb', 'wifi'
  final String pin;
  final int pinTtlSec;
  final String clientName;
  final bool streamActive;
  final int latencyMs;

  factory LinkState.fromMap(Map<dynamic, dynamic> m) {
    return LinkState(
      status: (m['status'] as String?) ?? 'idle',
      mode: (m['mode'] as String?) ?? 'usb',
      pin: (m['pin'] as String?) ?? '',
      pinTtlSec: (m['pinTtlSec'] as num?)?.toInt() ?? 0,
      clientName: (m['clientName'] as String?) ?? '',
      streamActive: (m['streamActive'] as bool?) ?? false,
      latencyMs: (m['latencyMs'] as num?)?.toInt() ?? 24,
    );
  }

  Map<String, dynamic> toMap() => {
    'status': status,
    'mode': mode,
    'pin': pin,
    'pinTtlSec': pinTtlSec,
    'clientName': clientName,
    'streamActive': streamActive,
    'latencyMs': latencyMs,
  };

  LinkState copyWith({
    String? status,
    String? mode,
    String? pin,
    int? pinTtlSec,
    String? clientName,
    bool? streamActive,
    int? latencyMs,
  }) {
    return LinkState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      pin: pin ?? this.pin,
      pinTtlSec: pinTtlSec ?? this.pinTtlSec,
      clientName: clientName ?? this.clientName,
      streamActive: streamActive ?? this.streamActive,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}
