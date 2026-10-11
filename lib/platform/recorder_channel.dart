import 'package:flutter/services.dart';

import 'models/device_caps.dart';
import 'models/record_settings.dart';
import 'models/recorder_state.dart';

/// Единственный мост к Kotlin (см. docs/03, контракт v1).
/// Виджеты не вызывают MethodChannel напрямую — только через этот класс.
class RecorderChannel {
  RecorderChannel({BinaryMessenger? messenger})
    : _method = MethodChannel(
        'app.dotrec/recorder',
        const StandardMethodCodec(),
        messenger,
      ),
      _events = const EventChannel('app.dotrec/recorder_state');

  static const String methodName = 'app.dotrec/recorder';
  static const String eventName = 'app.dotrec/recorder_state';

  final MethodChannel _method;
  final EventChannel _events;

  Future<void> start(RecordSettings s) =>
      _method.invokeMethod<void>('start', s.toMap());

  Future<void> stop() => _method.invokeMethod<void>('stop');

  Future<void> pause() => _method.invokeMethod<void>('pause');

  Future<void> resume() => _method.invokeMethod<void>('resume');

  Future<DeviceCaps> getDeviceCaps() async {
    final Map<Object?, Object?>? m = await _method
        .invokeMethod<Map<Object?, Object?>>('getDeviceCaps');
    if (m == null) return const DeviceCaps();
    return DeviceCaps.fromMap(m);
  }

  Future<RecordSettings> getSettings() async {
    final Map<Object?, Object?>? m = await _method
        .invokeMethod<Map<Object?, Object?>>('getSettings');
    if (m == null) return const RecordSettings();
    return RecordSettings.fromMap(m);
  }

  Future<void> saveSettings(RecordSettings s) =>
      _method.invokeMethod<void>('saveSettings', s.toMap());

  Future<void> openAppSettings() =>
      _method.invokeMethod<void>('openAppSettings');

  Future<bool> requestAddTile() async {
    final bool? v = await _method.invokeMethod<bool>('requestAddTile');
    return v ?? false;
  }

  Future<void> openOverlaySettings() =>
      _method.invokeMethod<void>('openOverlaySettings');

  Future<void> openBatterySettings() =>
      _method.invokeMethod<void>('openBatterySettings');

  Future<void> startLinkServer({String mode = 'usb'}) =>
      _method.invokeMethod<void>('startLinkServer', {'mode': mode});

  Future<void> stopLinkServer() =>
      _method.invokeMethod<void>('stopLinkServer');

  Future<Map<String, dynamic>> getLinkState() async {
    final Map<Object?, Object?>? m = await _method
        .invokeMethod<Map<Object?, Object?>>('getLinkState');
    if (m == null) return {};
    return Map<String, dynamic>.from(m);
  }

  /// Поток состояния сервера DotRec Link (USB / Wi-Fi)
  Stream<Map<String, dynamic>> get linkState =>
      const EventChannel('app.dotrec/link_state')
          .receiveBroadcastStream()
          .map((dynamic e) => Map<String, dynamic>.from(e as Map));

  /// При подписке Kotlin сразу отдаёт текущее состояние, затем изменения.
  Stream<RecorderState> get state => _events.receiveBroadcastStream().map(
    (dynamic e) => RecorderState.fromMap(Map<Object?, Object?>.from(e as Map)),
  );
}
