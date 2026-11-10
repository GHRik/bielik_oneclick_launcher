import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/android_app_exit_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_exit_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/app_exit');
  const repository = AndroidAppExitRepository(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final lowMemory in [true, false]) {
    test('Decodes an Android exit report with lowMemory=$lowMemory', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'id': '123',
          'lowMemory': lowMemory,
          'code': 'ANDROID_EXIT_3_STATUS_0',
        },
      );
      final report = await repository.readPreviousExit();
      expect(report!.id, '123');
      expect(report.lowMemory, lowMemory);
      expect(report.code, 'ANDROID_EXIT_3_STATUS_0');
    });
  }

  test(
    'Returns no report when Android has no reportable previous exit',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      expect(await repository.readPreviousExit(), isNull);
    },
  );

  test(
    'Acknowledges the specific report through the platform adapter',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return null;
      });
      await repository.acknowledge(
        const AppExitReport(id: '123', lowMemory: false, code: 'UNKNOWN'),
      );
      expect(received!.method, 'acknowledgeExit');
      expect(received!.arguments, '123');
    },
  );
}
