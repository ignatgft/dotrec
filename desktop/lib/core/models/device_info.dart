enum DeviceTransport {
  usb,
  wifi,
}

enum AdbState {
  noCable,
  unauthorized,
  offline,
  ready,
}

class DeviceInfo {
  const DeviceInfo({
    required this.serial,
    required this.model,
    required this.androidVersion,
    required this.transport,
    required this.state,
    this.product = '',
    this.device = '',
  });

  final String serial;
  final String model;
  final String androidVersion;
  final DeviceTransport transport;
  final AdbState state;
  final String product;
  final String device;

  bool get isReady => state == AdbState.ready;

  String get displayName {
    if (model.isNotEmpty) return model;
    if (serial.isNotEmpty) return serial;
    return 'Устройство';
  }

  String get summary {
    final t = transport == DeviceTransport.usb ? 'USB' : 'Wi-Fi';
    final v = androidVersion.isNotEmpty ? ' · Android $androidVersion' : '';
    return '$displayName · $t$v';
  }

  DeviceInfo copyWith({
    String? serial,
    String? model,
    String? androidVersion,
    DeviceTransport? transport,
    AdbState? state,
    String? product,
    String? device,
  }) {
    return DeviceInfo(
      serial: serial ?? this.serial,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      transport: transport ?? this.transport,
      state: state ?? this.state,
      product: product ?? this.product,
      device: device ?? this.device,
    );
  }
}
