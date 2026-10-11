import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/services/browser_source_server.dart';

void main() {
  group('BrowserSourceServer tests', () {
    test('Server binds to loopback and validates token', () async {
      final server = BrowserSourceServer();
      final port = await server.start(port: 0);
      expect(port, greaterThan(0));
      expect(server.isRunning, isTrue);
      expect(server.url, contains('http://127.0.0.1:$port/?token='));

      final client = HttpClient();

      // 1. Request with invalid token -> 401
      final unauthReq =
          await client.getUrl(Uri.parse('http://127.0.0.1:$port/?token=wrong'));
      final unauthResp = await unauthReq.close();
      expect(unauthResp.statusCode, HttpStatus.unauthorized);

      // 2. Request with valid token -> 200 OK HTML with WebCodecs
      final okReq = await client.getUrl(Uri.parse(server.url));
      final okResp = await okReq.close();
      expect(okResp.statusCode, HttpStatus.ok);
      final body = await okResp.transform(const SystemEncoding().decoder).join();
      expect(body, contains('DotRec Link OBS Source'));
      expect(body, contains('VideoDecoder'));

      client.close();
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('WebSocket upgrade succeeds with valid token', () async {
      final server = BrowserSourceServer();
      final port = await server.start(port: 0);

      final ws = await WebSocket.connect(
          'ws://127.0.0.1:$port/ws?token=${server.token}');
      expect(ws.readyState, WebSocket.open);

      await ws.close();
      await server.stop();
    });
  });
}
