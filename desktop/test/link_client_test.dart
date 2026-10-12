import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/services/link_client.dart';
import 'package:dotrec_link_desktop/services/recording_service.dart';

void main() {
  group('LinkClient and Protocol tests', () {
    test('Socket handshake and frame reception over loopback', () async {
      // 1. Setup mock server on random port
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      server.listen((clientSocket) {
        final buffer = <int>[];
        clientSocket.listen((data) {
          buffer.addAll(data);
          final newline = buffer.indexOf(10);
          if (newline != -1) {
            final handshakeStr = utf8.decode(buffer.sublist(0, newline));
            final req = jsonDecode(handshakeStr);
            expect(req['protocol'], 'dotrec_link');
            expect(req['version'], 1);

            // Send OK response
            final resp = jsonEncode({
              'protocol': 'dotrec_link',
              'version': 1,
              'status': 'ok',
              'device': {
                'model': 'Pixel 8',
                'manufacturer': 'Google',
                'android_version': 15,
              },
              'session': {'token': 'test_token_123', 'port': port},
            });
            clientSocket.add(utf8.encode('$resp\n'));

            // Send 1 Config frame and 1 Video frame
            // Frame 1: Config (type 0x01)
            final configPayload = Uint8List.fromList([
              0x67,
              0x42,
              0x00,
              0x1f,
            ]); // SPS
            final f1 = ByteData(LinkClient.headerSize)
              ..setUint8(0, LinkClient.typeConfig)
              ..setUint8(1, LinkClient.flagKeyframe)
              ..setUint32(2, configPayload.length, Endian.big)
              ..setInt64(6, 0, Endian.big);
            clientSocket.add(f1.buffer.asUint8List());
            clientSocket.add(configPayload);

            // Frame 2: Video (type 0x02, IDR frame)
            final videoPayload = Uint8List.fromList([
              0x65,
              0x88,
              0x84,
              0x00,
            ]); // IDR slice
            final f2 = ByteData(LinkClient.headerSize)
              ..setUint8(0, LinkClient.typeVideo)
              ..setUint8(1, LinkClient.flagKeyframe)
              ..setUint32(2, videoPayload.length, Endian.big)
              ..setInt64(6, 1000000, Endian.big);
            clientSocket.add(f2.buffer.asUint8List());
            clientSocket.add(videoPayload);

            // Frame 3: Audio (type 0x03)
            final audioPayload = Uint8List.fromList([
              0xFF,
              0xF1,
              0x50,
              0x80,
            ]); // AAC packet
            final f3 = ByteData(LinkClient.headerSize)
              ..setUint8(0, LinkClient.typeAudio)
              ..setUint8(1, 0)
              ..setUint32(2, audioPayload.length, Endian.big)
              ..setInt64(6, 1000000, Endian.big);
            clientSocket.add(f3.buffer.asUint8List());
            clientSocket.add(audioPayload);
          }
        });
      });

      // 2. Connect LinkClient
      final client = LinkClient();
      final connected = await client.connect(
        host: '127.0.0.1',
        connectPort: port,
      );
      expect(connected, isTrue);

      // Wait for frames
      final frame = await client.videoStream.first;
      expect(frame.isKeyframe, isTrue);
      expect(frame.ptsUs, 1000000);
      expect(frame.data, [0x65, 0x88, 0x84, 0x00]);
      expect(client.spsPps, [0x67, 0x42, 0x00, 0x1f]);
      expect(client.sessionToken, 'test_token_123');

      final aFrame = await client.audioStream.first;
      expect(aFrame.ptsUs, 1000000);
      expect(aFrame.data, [0xFF, 0xF1, 0x50, 0x80]);

      client.disconnect();
      client.dispose();
      await server.close();
    });

    test('RecordingService records video and audio streams to file', () async {
      final rec = RecordingService();
      final tempDir = Directory.systemTemp.createTempSync('dotrec_rec_test');
      try {
        expect(
          RecordingService.hasStartCode(Uint8List.fromList([0, 0, 1])),
          isTrue,
        );
        expect(
          RecordingService.hasStartCode(Uint8List.fromList([0, 0, 0, 1])),
          isTrue,
        );
        expect(
          RecordingService.hasStartCode(Uint8List.fromList([1, 2, 3])),
          isFalse,
        );

        final initialSps = Uint8List.fromList([0x67, 0x42, 0x00, 0x1f]);
        final filePath = await rec.startRecording(initialSps, tempDir.path);
        expect(rec.isRecording, isTrue);
        expect(File(filePath).existsSync(), isTrue);

        rec.writeVideoFrame(
          LinkVideoFrame(
            data: Uint8List.fromList([0x65, 0x88]),
            isKeyframe: true,
            ptsUs: 1000,
          ),
          initialSps,
        );

        rec.writeAudioFrame(Uint8List.fromList([0xFF, 0xF1, 0x50]));
        expect(rec.bytesWritten, greaterThan(0));

        final res = await rec.stopRecording();
        expect(rec.isRecording, isFalse);
        expect(res, isNotNull);
        expect(res!.bytesWritten, greaterThan(0));
        expect(File(res.filePath).lengthSync(), res.bytesWritten);

        // Screenshot
        final sPath = await rec.saveScreenshot(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
          tempDir.path,
        );
        expect(File(sPath).existsSync(), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
