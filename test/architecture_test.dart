import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Layers respect their dependency boundaries', () {
    const package = 'package:bielik_oneclick_launcher/src/';
    for (final layer in ['domain', 'data', 'presentation']) {
      final files = Directory('lib/src/$layer')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final imports = RegExp(
          r"^(?:import|export) '([^']+)'",
          multiLine: true,
        ).allMatches(file.readAsStringSync());
        for (final match in imports) {
          final uri = match.group(1)!;
          if (layer == 'domain') {
            expect(
              uri.startsWith('dart:') || uri.startsWith('${package}domain/'),
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
        }
      }
    }
  });
}
