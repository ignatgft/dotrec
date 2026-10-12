import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/services/link_client.dart';
import 'package:dotrec_link_desktop/services/recording_service.dart';

void main() {
  group('RecordingService tests', () {
    test('startRecording, writeVideoFrame and stopRecording write file with start codes', () async {
      final service = RecordingService();
      final spsPps = Uint8List.fromList([0x67, 0x42, 0x00, 0x1f]); // SPS
      final filePath = await service.startRecording(spsPps);

      expect(service.isRecording, isTrue);
      expect(File(filePath).existsSync(), isTrue);

      // Write video frame (IDR)
      final frame = LinkVideoFrame(
        data: Uint8List.fromList([0x65, 0x88, 0x84, 0x00]),
        isKeyframe: true,
        ptsUs: 1000000,
      );
      service.writeVideoFrame(frame, spsPps);

      final result = await service.stopRecording();
      expect(result, isNotNull);
      expect(result!.bytesWritten, greaterThan(0));
      expect(service.isRecording, isFalse);

      final fileBytes = await File(filePath).readAsBytes();
      // Must contain Annex B start codes: 00 00 00 01
      expect(fileBytes.sublist(0, 4), [0x00, 0x00, 0x00, 0x01]);

      // Cleanup
      try {
        File(filePath).deleteSync();
      } catch (_) {}
    });

    test('saveScreenshot writes PNG to file', () async {
      final service = RecordingService();
      final dummyPng = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final path = await service.saveScreenshot(dummyPng);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), dummyPng);

      // Cleanup
      try {
        file.deleteSync();
      } catch (_) {}
    });
  });
}
