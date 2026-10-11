import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/package_windows.dart' as packager;

void main() {
  group('Desktop Packaging validation', () {
    test('run package_windows and verify bundle layout and manifest', () async {
      // Execute packaging tool
      packager.main([]);

      final distDir = Directory('build/dist/DotRec-Link-v1.0.0-windows-x64');
      expect(distDir.existsSync(), isTrue);

      final manifestFile = File('${distDir.path}/manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifestJson =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifestJson['package'], equals('DotRec-Link-Desktop'));
      expect(manifestJson['version'], equals('1.0.0+1'));
      expect(manifestJson['target'], equals('windows-x64'));

      final files = manifestJson['files'] as List;
      expect(files, isNotEmpty);

      // Verify files exist in bundle
      expect(File('${distDir.path}/README.txt').existsSync(), isTrue);
      expect(File('${distDir.path}/LICENSE.txt').existsSync(), isTrue);
      expect(File('${distDir.path}/config.default.json').existsSync(), isTrue);
      expect(File('${distDir.path}/DotRec-Link.exe').existsSync(), isTrue);
      expect(
          File('${distDir.path}/assets/fonts/Doto-Variable.ttf').existsSync(),
          isTrue);
    });
  });
}
