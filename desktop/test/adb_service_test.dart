import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/core/models/device_info.dart';
import 'package:dotrec_link_desktop/services/adb_service.dart';

void main() {
  group('AdbService tests', () {
    test('parseDevicesOutput parses various device formats correctly', () {
      const mockOutput = '''
List of devices attached
28271JEHN01358         device product:husky model:Pixel_8_Pro device:husky transport_id:1
emulator-5554          unauthorized transport_id:2
192.168.1.150:5555     offline product:tangorpro model:Pixel_Tablet device:tangorpro transport_id:3
''';

      final service = AdbService();
      final devices = service.parseDevicesOutput(mockOutput);

      expect(devices.length, 3);

      // Device 1
      expect(devices[0].serial, '28271JEHN01358');
      expect(devices[0].model, 'Pixel 8 Pro');
      expect(devices[0].state, AdbState.ready);
      expect(devices[0].transport, DeviceTransport.usb);
      expect(devices[0].isReady, isTrue);

      // Device 2 (unauthorized)
      expect(devices[1].serial, 'emulator-5554');
      expect(devices[1].state, AdbState.unauthorized);
      expect(devices[1].transport, DeviceTransport.usb);
      expect(devices[1].isReady, isFalse);

      // Device 3 (wifi + offline)
      expect(devices[2].serial, '192.168.1.150:5555');
      expect(devices[2].model, 'Pixel Tablet');
      expect(devices[2].state, AdbState.offline);
      expect(devices[2].transport, DeviceTransport.wifi);
      expect(devices[2].isReady, isFalse);
    });

    test('parseDevicesOutput handles empty device list', () {
      const mockOutput = 'List of devices attached\n\n';
      final service = AdbService();
      final devices = service.parseDevicesOutput(mockOutput);
      expect(devices, isEmpty);
    });

    test('AdbService invokes custom CommandRunner correctly', () async {
      final runnerCalls = <List<String>>[];

      Future<ProcessResult> mockRunner(String exe, List<String> args) async {
        runnerCalls.add([exe, ...args]);
        if (args.contains('version')) {
          return ProcessResult(1, 0, 'Android Debug Bridge version 1.0.41', '');
        }
        if (args.contains('forward')) {
          return ProcessResult(2, 0, '', '');
        }
        return ProcessResult(3, 0, '', '');
      }

      final service = AdbService(
        adbPath: 'mock_adb',
        commandRunner: mockRunner,
      );

      final isInstalled = await service.checkAdbInstalled();
      expect(isInstalled, isTrue);

      final forwarded = await service.forwardPort('device123', 48211, 48211);
      expect(forwarded, isTrue);

      expect(runnerCalls.length, 2);
      expect(runnerCalls[0], ['mock_adb', 'version']);
      expect(runnerCalls[1], [
        'mock_adb',
        '-s',
        'device123',
        'forward',
        'tcp:48211',
        'tcp:48211',
      ]);
    });
  });
}
