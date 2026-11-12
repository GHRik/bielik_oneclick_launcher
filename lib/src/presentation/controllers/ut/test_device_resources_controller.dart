import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/device_resources_controller.dart';

class _ResourcesRepository implements DeviceResourcesRepository {
  final pending = Completer<DeviceResources>();
  int reads = 0;

  @override
  Future<DeviceResources> read() {
    reads++;
    return pending.future;
  }
}

void main() {
  group('DeviceResourcesController', () {
    test('Coalesces concurrent refresh requests', () async {
      final repository = _ResourcesRepository();
      final controller = DeviceResourcesController(repository);
      addTearDown(controller.dispose);

      final first = controller.refresh();
      final second = controller.refresh();
      final readsWhilePending = repository.reads;
      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await Future.wait([first, second]);

      expect(readsWhilePending, 1);
    });

    test('Repeats the read for a request made during a read', () async {
      final repository = _ResourcesRepository();
      final controller = DeviceResourcesController(repository);
      addTearDown(controller.dispose);

      final first = controller.refresh();
      final second = controller.refresh();
      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await Future.wait([first, second]);

      expect(repository.reads, 2);
    });

    test('Reads once when no request arrives during the read', () async {
      final repository = _ResourcesRepository();
      final controller = DeviceResourcesController(repository);
      addTearDown(controller.dispose);

      final refresh = controller.refresh();
      repository.pending.complete(const DeviceResources(availableRamBytes: 1));
      await refresh;

      expect(repository.reads, 1);
    });

    test('Does not notify listeners after disposal', () async {
      final repository = _ResourcesRepository();
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
      final repository = _ResourcesRepository();
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

      expect(controller.resources.availableRamBytes, 4000000000);
      expect(controller.resources.freeStorageBytes, 10000000000);
    });
  });
}
