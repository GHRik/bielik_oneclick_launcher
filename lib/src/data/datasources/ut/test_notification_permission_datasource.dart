import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/notification_permission_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPermissionDataSource', () {
    const source = NotificationPermissionDataSource();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(source.channel, null));

    test('Asks the platform for the permission', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(source.channel, (call) async {
        calls.add(call.method);
        return true;
      });

      await source.request();

      expect(calls, ['request']);
    });

    test('Completes when the user refuses', () async {
      messenger.setMockMethodCallHandler(source.channel, (_) async => false);

      await expectLater(source.request(), completes);
    });

    test('Completes when the platform reports an error', () async {
      messenger.setMockMethodCallHandler(
        source.channel,
        (_) async => throw PlatformException(code: 'DENIED'),
      );

      await expectLater(source.request(), completes);
    });

    test('Stops waiting when no answer arrives', () async {
      final unanswered = Completer<bool>();
      addTearDown(() => unanswered.complete(false));
      messenger.setMockMethodCallHandler(
        source.channel,
        (_) => unanswered.future,
      );

      await expectLater(
        const NotificationPermissionDataSource(
          timeout: Duration(milliseconds: 20),
        ).request(),
        completes,
      );
    });

    test('Completes on a platform without the channel', () async {
      await expectLater(source.request(), completes);
    });
  });
}
