import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';

class _Source extends DeviceResourcesDataSource {
  Map<String, dynamic> values = {};
  Exception? failure;

  @override
  Future<Map<String, dynamic>> read() async {
    if (failure != null) throw failure!;
    return values;
  }
}

void main() {
  group('LocalDeviceResourcesRepository', () {
    final fields = <String, int>{
      'totalRamBytes': 8000000000,
      'availableRamBytes': 3500000000,
      'freeStorageBytes': 20000000000,
    };
    int? value(DeviceResources result, String field) => switch (field) {
      'totalRamBytes' => result.totalRamBytes,
      'availableRamBytes' => result.availableRamBytes,
      _ => result.freeStorageBytes,
    };
    for (final entry in fields.entries) {
      test('read maps the ${entry.key} byte count from its source', () async {
        final source = _Source()..values = {entry.key: entry.value};

        final result = await LocalDeviceResourcesRepository(source).read();

        expect(value(result, entry.key), entry.value);
      });
    }

    test('Preserves a missing total RAM reading', () async {
      final result = await LocalDeviceResourcesRepository(_Source()).read();

      expect(result.totalRamBytes, isNull);
    });

    test('Preserves zero available RAM as a valid reading', () async {
      final source = _Source()..values = {'availableRamBytes': 0};

      final result = await LocalDeviceResourcesRepository(source).read();

      expect(result.availableRamBytes, 0);
    });

    test('Treats negative free storage as unknown', () async {
      final source = _Source()..values = {'freeStorageBytes': -1};

      final result = await LocalDeviceResourcesRepository(source).read();

      expect(result.freeStorageBytes, isNull);
    });

    final failures = <String, Exception>{
      'missing platform implementation': MissingPluginException(),
      'native failure': PlatformException(code: 'unavailable'),
    };
    for (final entry in failures.entries) {
      test('Reports unknown resources after a ${entry.key}', () async {
        final source = _Source()..failure = entry.value;

        final result = await LocalDeviceResourcesRepository(source).read();

        expect(result.availableRamBytes, isNull);
        expect(result.freeStorageBytes, isNull);
      });
    }
  });
}
