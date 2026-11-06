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
  test(
    'Maps native byte counts into decimal GB and preserves missing fields',
    () async {
      final source = FakeSource()
        ..values = {
          'totalRamBytes': 8000000000,
          'availableRamBytes': 3500000000,
          'freeStorageBytes': 20000000000,
        };
      final repository = LocalDeviceResourcesRepository(source);
      final result = await repository.read();
      expect(result.totalRamGb, 8);
      expect(result.availableRamGb, 3.5);
      expect(result.freeStorageGb, 20);
      source.values = {'availableRamBytes': 0, 'freeStorageBytes': -1};
      final partial = await repository.read();
      expect(partial.totalRamGb, isNull);
      expect(partial.availableRamGb, 0);
      expect(partial.freeStorageGb, isNull);
    },
  );

  test(
    'Unsupported platforms and native failures report unknown resources',
    () async {
      final source = FakeSource();
      final repository = LocalDeviceResourcesRepository(source);
      for (final failure in [
        MissingPluginException(),
        PlatformException(code: 'unavailable'),
      ]) {
        source.failure = failure;
        final result = await repository.read();
        expect(result.availableRamGb, isNull);
        expect(result.freeStorageGb, isNull);
      }
    },
  );

  test(
    'Controller coalesces reads and ignores completion after disposal',
    () async {
      final repository = PendingResources();
      final controller = DeviceResourcesController(repository);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final first = controller.refresh();
      final second = controller.refresh();
      expect(repository.reads, 1);
      controller.dispose();
      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await Future.wait([first, second]);
      expect(notifications, 0);
    },
  );

  test('Controller exposes readings to the view', () async {
    final repository = PendingResources();
    final controller = DeviceResourcesController(repository);
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
    controller.dispose();
  });
}
