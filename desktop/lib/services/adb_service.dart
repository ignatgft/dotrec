import 'dart:async';
import 'dart:io';

import '../core/models/device_info.dart';

typedef CommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class AdbService {
  AdbService({String? adbPath, CommandRunner? commandRunner})
    : _adbPath = adbPath ?? _resolveDefaultAdbPath(),
      _runner = commandRunner ?? Process.run;

  String _adbPath;
  final CommandRunner _runner;
  Timer? _pollTimer;
  final _devicesController = StreamController<List<DeviceInfo>>.broadcast();

  String get adbPath => _adbPath;
  Stream<List<DeviceInfo>> get devicesStream => _devicesController.stream;

  static String _resolveDefaultAdbPath() {
    final sep = Platform.pathSeparator;
    final exeName = Platform.isWindows ? 'adb.exe' : 'adb';
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    final androidHome =
        Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];

    final candidates = [
      if (androidHome != null) '$androidHome${sep}platform-tools$sep$exeName',
      if (localAppData != null)
        '$localAppData${sep}Android${sep}Sdk${sep}platform-tools$sep$exeName',
      if (home != null)
        '$home${sep}AppData${sep}Local${sep}Android${sep}Sdk${sep}platform-tools$sep$exeName',
      if (home != null)
        '$home${sep}Android${sep}Sdk${sep}platform-tools$sep$exeName',
      if (home != null)
        '$home${sep}Library${sep}Android${sep}sdk${sep}platform-tools$sep$exeName',
      if (Platform.isWindows) ...[
        r'D:\andoidsdk\platform-tools\adb.exe',
        r'C:\Android\Sdk\platform-tools\adb.exe',
        r'D:\Android\Sdk\platform-tools\adb.exe',
      ],
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) {
        return c;
      }
    }
    return exeName;
  }

  void updateAdbPath(String path) {
    _adbPath = path;
  }

  Future<bool> checkAdbInstalled() async {
    try {
      final res = await _runner(_adbPath, ['version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<DeviceInfo>> getDevices() async {
    try {
      final res = await _runner(_adbPath, ['devices', '-l']);
      if (res.exitCode != 0) {
        return [];
      }
      return parseDevicesOutput(res.stdout.toString());
    } catch (_) {
      return [];
    }
  }

  List<DeviceInfo> parseDevicesOutput(String stdout) {
    final lines = stdout.split(RegExp(r'\r?\n'));
    final devices = <DeviceInfo>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty ||
          line.startsWith('List of devices') ||
          line.startsWith('* daemon')) {
        continue;
      }

      // format: <serial> <state> [product:...] [model:...] [device:...] [transport_id:...]
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final serial = parts[0];
      final stateStr = parts[1];

      AdbState state;
      if (stateStr == 'device') {
        state = AdbState.ready;
      } else if (stateStr == 'unauthorized') {
        state = AdbState.unauthorized;
      } else if (stateStr == 'offline') {
        state = AdbState.offline;
      } else {
        state = AdbState.noCable;
      }

      String model = '';
      String product = '';
      String device = '';

      for (int i = 2; i < parts.length; i++) {
        final kv = parts[i];
        if (kv.startsWith('model:')) {
          model = kv.substring(6).replaceAll('_', ' ');
        } else if (kv.startsWith('product:')) {
          product = kv.substring(8);
        } else if (kv.startsWith('device:')) {
          device = kv.substring(7);
        }
      }

      final isWifi = serial.contains(':');
      final transport = isWifi ? DeviceTransport.wifi : DeviceTransport.usb;

      devices.add(
        DeviceInfo(
          serial: serial,
          model: model.isNotEmpty ? model : serial,
          androidVersion: '', // populated asynchronously if ready
          transport: transport,
          state: state,
          product: product,
          device: device,
        ),
      );
    }

    return devices;
  }

  Future<String> getAndroidVersion(String serial) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'shell',
        'getprop',
        'ro.build.version.release',
      ]);
      if (res.exitCode == 0) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return '';
  }

  Future<bool> forwardPort(String serial, int localPort, int remotePort) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'forward',
        'tcp:$localPort',
        'tcp:$remotePort',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePortForward(String serial, int localPort) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'forward',
        '--remove',
        'tcp:$localPort',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDotRecInstalled(String serial) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'shell',
        'pm',
        'path',
        'app.dotrec',
      ]);
      return res.exitCode == 0 && res.stdout.toString().contains('package:');
    } catch (_) {
      return false;
    }
  }

  Future<bool> launchDotRec(String serial) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'shell',
        'monkey',
        '-p',
        'app.dotrec',
        '-c',
        'android.intent.category.LAUNCHER',
        '1',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendKeyEvent(String serial, int keyCode) async {
    try {
      final res = await _runner(_adbPath, [
        '-s',
        serial,
        'shell',
        'input',
        'keyevent',
        '$keyCode',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendHome(String serial) => sendKeyEvent(serial, 3);
  Future<bool> sendBack(String serial) => sendKeyEvent(serial, 4);
  Future<bool> sendPower(String serial) => sendKeyEvent(serial, 26);
  Future<bool> sendRecents(String serial) => sendKeyEvent(serial, 187);

  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      final devices = await getDevices();
      final updated = <DeviceInfo>[];
      for (final dev in devices) {
        if (dev.state == AdbState.ready && dev.androidVersion.isEmpty) {
          final ver = await getAndroidVersion(dev.serial);
          updated.add(dev.copyWith(androidVersion: ver));
        } else {
          updated.add(dev);
        }
      }
      if (_devicesController.isClosed) return;
      _devicesController.add(updated);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stopPolling();
    _devicesController.close();
  }
}
