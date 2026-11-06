import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Layers respect their dependency boundaries', () {
    const package = 'package:bielik_oneclick_launcher/src/';
    const domainLibraries = {
      'dart:async', 'dart:collection', 'dart:convert', 'dart:math',
      'package:characters/characters.dart',
    };
    const uiPackages = [
      'package:material_ui/', 'package:flutter_chat_ui/', 'package:flutter_chat_core/',
    ];
    for (final layer in ['domain', 'data', 'presentation']) {
      final files = Directory('lib/src/$layer')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final imports = RegExp(
          r"""^(?:import|export)\s+['"]([^'"]+)['"]""",
          multiLine: true,
        ).allMatches(file.readAsStringSync());
        for (final match in imports) {
          final uri = match.group(1)!;
          if (layer == 'domain') {
            expect(
              domainLibraries.contains(uri) || uri.startsWith('${package}domain/'),
              isTrue,
              reason: 'Domain must be pure Dart: ${file.path} imports $uri',
            );
          } else if (uri.startsWith(package)) {
            expect(
              uri.startsWith('${package}domain/') ||
                  uri.startsWith('$package$layer/'),
              isTrue,
              reason: 'Invalid dependency in ${file.path}: $uri',
            );
          }
          if (layer == 'data') {
            expect(uiPackages.any(uri.startsWith), isFalse,
                reason: 'Data imports UI: ${file.path} imports $uri');
            if (uri.startsWith('package:flutter/')) {
              expect(
                {'package:flutter/services.dart', 'package:flutter/foundation.dart'}.contains(uri),
                isTrue,
                reason: 'Data imports Flutter UI: ${file.path} imports $uri',
              );
            }
          }
        }
      }
    }
  });
}
