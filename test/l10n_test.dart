import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Все ARB должны иметь одинаковые ключи и плейсхолдеры.
void main() {
  test('ARB parity across locales', () {
    final Directory dir = Directory('lib/l10n');
    final List<File> arbs = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs.length, greaterThanOrEqualTo(7));
    Map<String, Object?> base = {};
    for (final File f in arbs) {
      final Map<String, Object?> json =
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final Set<String> keys = {
        for (final String k in json.keys)
          if (!k.startsWith('@')) k,
      };
      if (base.isEmpty) {
        base = json;
      } else {
        final Set<String> baseKeys = {
          for (final String k in base.keys)
            if (!k.startsWith('@')) k,
        };
        expect(keys, baseKeys, reason: 'keys mismatch in ${f.path}');
      }
      // Плейсхолдеры совпадают с шаблоном.
      for (final String k in keys) {
        final Object? meta = json['@$k'];
        final Object? baseMeta = base['@$k'];
        expect(
          meta == null,
          baseMeta == null,
          reason: 'placeholder meta mismatch for $k in ${f.path}',
        );
      }
    }
  });
}
