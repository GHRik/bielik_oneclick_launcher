import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final destination = Platform.environment['E2E_OUTPUT_DIR'];
  if (destination == null || destination.isEmpty) {
    throw StateError(
      'Run through test/e2e/run_android_e2e.dart to collect artifacts.',
    );
  }
  final directory = await Directory(destination).create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      await File('${directory.path}/device-report.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
    },
    onScreenshot: (name, bytes, [arguments]) async {
      final screenshots = await Directory('${directory.path}/screenshots')
          .create(recursive: true);
      final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await File('${screenshots.path}/$safeName.png')
          .writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
