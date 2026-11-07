import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _package = 'package:bielik_oneclick_launcher/src/';

Iterable<({String path, String uri})> _imports(String layer) sync* {
  final files = Directory('lib/src/$layer')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.uri.pathSegments.contains('ut'));
  expect(
    files,
    isNotEmpty,
    reason: 'The $layer layer must contain source files',
  );
  for (final file in files) {
    final matches = RegExp(
      r"""^(?:import|export)\s+['"]([^'"]+)['"]""",
      multiLine: true,
    ).allMatches(file.readAsStringSync());
    for (final match in matches) {
      yield (path: file.path, uri: match.group(1)!);
    }
  }
}

void main() {
  group('Layer dependency boundaries', () {
    test(
      'Production layers do not import unit tests or their test framework',
      () {
        for (final layer in ['domain', 'data', 'presentation']) {
          for (final dependency in _imports(layer)) {
            expect(
              dependency.uri.split('/'),
              isNot(contains('ut')),
              reason: '${dependency.path} imports ${dependency.uri}',
            );
            expect(
              dependency.uri.startsWith('package:flutter_test/'),
              isFalse,
              reason: '${dependency.path} imports ${dependency.uri}',
            );
          }
        }
      },
    );

    test('Domain depends only on pure Dart libraries and domain code', () {
      const libraries = {
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:math',
        'package:characters/characters.dart',
      };
      for (final dependency in _imports('domain')) {
        expect(
          libraries.contains(dependency.uri) ||
              dependency.uri.startsWith('${_package}domain/'),
          isTrue,
          reason: '${dependency.path} imports ${dependency.uri}',
        );
      }
    });

    for (final layer in ['data', 'presentation']) {
      test('$layer depends only on itself and domain within src', () {
        for (final dependency in _imports(layer)) {
          if (!dependency.uri.startsWith(_package)) continue;
          expect(
            dependency.uri.startsWith('${_package}domain/') ||
                dependency.uri.startsWith('$_package$layer/'),
            isTrue,
            reason: '${dependency.path} imports ${dependency.uri}',
          );
        }
      });
    }

    for (final layer in ['domain', 'data', 'presentation']) {
      test('$layer receives configuration through injection', () {
        for (final dependency in _imports(layer)) {
          expect(
            dependency.uri.startsWith(
              'package:bielik_oneclick_launcher/configuration/',
            ),
            isFalse,
            reason: '${dependency.path} imports ${dependency.uri}',
          );
        }
      });
    }

    test('Data does not depend on UI packages', () {
      const uiPackages = [
        'package:material_ui/',
        'package:flutter_chat_ui/',
        'package:flutter_chat_core/',
      ];
      for (final dependency in _imports('data')) {
        expect(
          uiPackages.any(dependency.uri.startsWith),
          isFalse,
          reason: '${dependency.path} imports ${dependency.uri}',
        );
      }
    });

    test('Data uses only Flutter platform services and foundation', () {
      for (final dependency in _imports('data')) {
        if (!dependency.uri.startsWith('package:flutter/')) continue;
        expect(
          {
            'package:flutter/services.dart',
            'package:flutter/foundation.dart',
          }.contains(dependency.uri),
          isTrue,
          reason: '${dependency.path} imports ${dependency.uri}',
        );
      }
    });
  });

  test('The default test entry point registers every colocated unit test', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.contains('ut'))
        .where(
          (file) =>
              file.uri.pathSegments.last.startsWith('test_') &&
              file.path.endsWith('.dart'),
        );
    final runner = File('test/ut_test.dart').readAsStringSync();
    final registrations = RegExp(
      r"""^import\s+['"](package:bielik_oneclick_launcher/[^'"]+/ut/test_[^'"]+\.dart)['"]""",
      multiLine: true,
    ).allMatches(runner).map((match) => match.group(1)!).toSet();
    final expected = files
        .map(
          (file) =>
              'package:bielik_oneclick_launcher/${file.uri.pathSegments.skip(1).join('/')}',
        )
        .toSet();

    expect(expected, isNotEmpty);
    expect(registrations, unorderedEquals(expected));
  });
}
