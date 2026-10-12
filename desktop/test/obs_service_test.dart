import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/services/obs_service.dart';

void main() {
  group('ObsService tests', () {
    test('obs-websocket v5 handshake and CreateInput request', () async {
      // 1. Setup mock obs-websocket server
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      server.transform(WebSocketTransformer()).listen((ws) {
        // Send op 0 Hello (no auth required for test)
        ws.add(
          jsonEncode({
            'op': 0,
            'd': {'obsWebSocketVersion': '5.0.0', 'rpcVersion': 1},
          }),
        );

        ws.listen((rawMsg) {
          final json = jsonDecode(rawMsg.toString()) as Map<String, dynamic>;
          final op = json['op'] as int?;
          final d = json['d'] as Map<String, dynamic>? ?? {};

          if (op == 1) {
            // Identify -> respond with op 2 Identified
            ws.add(
              jsonEncode({
                'op': 2,
                'd': {'negotiatedRpcVersion': 1},
              }),
            );
          } else if (op == 6) {
            // Request
            final reqType = d['requestType'] as String?;
            final reqId = d['requestId'] as String?;

            if (reqType == 'GetCurrentProgramScene') {
              ws.add(
                jsonEncode({
                  'op': 7,
                  'd': {
                    'requestType': 'GetCurrentProgramScene',
                    'requestId': reqId,
                    'requestStatus': {'result': true, 'code': 100},
                    'responseData': {'sceneName': 'Scene 1'},
                  },
                }),
              );
            } else if (reqType == 'CreateInput') {
              final reqData = d['requestData'] as Map<String, dynamic>?;
              expect(reqData?['inputKind'], 'browser_source');
              expect(reqData?['inputName'], 'DotRec Screen');
              ws.add(
                jsonEncode({
                  'op': 7,
                  'd': {
                    'requestType': 'CreateInput',
                    'requestId': reqId,
                    'requestStatus': {'result': true, 'code': 100},
                  },
                }),
              );
            }
          }
        });
      });

      // 2. Connect ObsService
      final obs = ObsService();
      final connected = await obs.connect(port: port);
      expect(connected, isTrue);
      expect(obs.status, ObsStatus.connected);

      // 3. Add Browser Source
      final sourceAdded = await obs.addBrowserSource(
        url: 'http://127.0.0.1:48212/?token=test',
        sceneName: 'Scene 1',
      );
      expect(sourceAdded, isTrue);

      obs.disconnect();
      obs.dispose();
      await server.close(force: true);
    });
  });
}
