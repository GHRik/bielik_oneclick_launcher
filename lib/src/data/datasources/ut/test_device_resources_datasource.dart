import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceResourcesDataSource', () {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    const source = DeviceResourcesDataSource();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (_) async => '/mock/support');
    });

    tearDown(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(pathProvider, null);
      messenger.setMockMethodCallHandler(
        DeviceResourcesDataSource.channel,
        null,
      );
    });

    test(
      'read passes the application support path to the native channel',
      () async {
        MethodCall? request;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(DeviceResourcesDataSource.channel, (
              call,
            ) async {
              request = call;
              return <String, dynamic>{};
            });

        await source.read();

        expect(request!.method, 'read');
        expect(request!.arguments, {'storagePath': '/mock/support'});
      },
    );

    test(
      'read returns resource values received from the native channel',
      () async {
        final expected = {
          'totalRamBytes': 8000000000,
          'availableRamBytes': 4000000000,
          'freeStorageBytes': 20000000000,
        };
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              DeviceResourcesDataSource.channel,
              (_) async => expected,
            );

        final result = await source.read();

        expect(result, expected);
      },
    );

    test(
      'read returns an empty map when the native channel returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              DeviceResourcesDataSource.channel,
              (_) async => null,
            );

        expect(await source.read(), isEmpty);
      },
    );

    test('read propagates native failures to the repository', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DeviceResourcesDataSource.channel, (
            _,
          ) async {
            throw PlatformException(code: 'unavailable');
          });

      await expectLater(source.read(), throwsA(isA<PlatformException>()));
    });
  });
}
