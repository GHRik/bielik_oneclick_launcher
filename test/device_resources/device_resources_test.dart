import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/device_resources_controller.dart';

class FakeSource extends DeviceResourcesDataSource {
  Map<String, dynamic> values = {};
  Exception? failure;

  @override
  Future<Map<String, dynamic>> read() async {
    if (failure != null) throw failure!;
    return values;
  }
}

class PendingResources implements DeviceResourcesRepository {
  final pending = Completer<DeviceResources>();
  int reads = 0;

  @override
  Future<DeviceResources> read() {
    reads++;
    return pending.future;
  }
}

void main() {
  group('Native device resource conversion', () {
    final fields = <String, double>{
      'totalRamBytes': 8,
      'availableRamBytes': 3.5,
      'freeStorageBytes': 20,
    };
    double? value(DeviceResources result, String field) => switch (field) {
      'totalRamBytes' => result.totalRamGb,
      'availableRamBytes' => result.availableRamGb,
      _ => result.freeStorageGb,
    };
    for (final entry in fields.entries) {
      test('Converts ${entry.key} from bytes to decimal GB', () async {
        final source = FakeSource()
          ..values = {entry.key: (entry.value * 1000000000).toInt()};

        final result = await LocalDeviceResourcesRepository(source).read();

        expect(value(result, entry.key), entry.value);
      });
    }

    test('Preserves a missing total RAM reading', () async {
      final result = await LocalDeviceResourcesRepository(FakeSource()).read();

      expect(result.totalRamGb, isNull);
    });

    test('Preserves zero available RAM as a valid reading', () async {
      final source = FakeSource()..values = {'availableRamBytes': 0};

      final result = await LocalDeviceResourcesRepository(source).read();

      expect(result.availableRamGb, 0);
    });

    test('Treats negative free storage as unknown', () async {
      final source = FakeSource()..values = {'freeStorageBytes': -1};

      final result = await LocalDeviceResourcesRepository(source).read();

      expect(result.freeStorageGb, isNull);
    });

    final failures = <String, Exception>{
      'missing platform implementation': MissingPluginException(),
      'native failure': PlatformException(code: 'unavailable'),
    };
    for (final entry in failures.entries) {
      test('Reports unknown resources after a ${entry.key}', () async {
        final source = FakeSource()..failure = entry.value;

        final result = await LocalDeviceResourcesRepository(source).read();

        expect(result.availableRamGb, isNull);
        expect(result.freeStorageGb, isNull);
      });
    }
  });

  group('Device resource controller', () {
    test('Coalesces concurrent refresh requests', () async {
      final repository = PendingResources();
      final controller = DeviceResourcesController(repository);
      addTearDown(controller.dispose);

      final first = controller.refresh();
      final second = controller.refresh();
      final readsWhilePending = repository.reads;
      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await Future.wait([first, second]);

      expect(readsWhilePending, 1);
    });

    test('Does not notify listeners after disposal', () async {
      final repository = PendingResources();
      final controller = DeviceResourcesController(repository);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final refresh = controller.refresh();
      controller.dispose();

      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await refresh;

      expect(notifications, 0);
    });

    test('Exposes refreshed readings to the view', () async {
      final repository = PendingResources();
      final controller = DeviceResourcesController(repository);
      addTearDown(controller.dispose);
      final refresh = controller.refresh();
      repository.pending.complete(
        const DeviceResources(
          availableRamBytes: 4000000000,
          freeStorageBytes: 10000000000,
        ),
      );

      await refresh;

      expect(controller.resources.availableRamGb, 4);
      expect(controller.resources.freeStorageGb, 10);
    });
  });
}
