import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';

void main() {
  group('DeviceResources', () {
    test('totalRamGb converts total RAM bytes to decimal GB', () {
      const resources = DeviceResources(totalRamBytes: 8000000000);

      expect(resources.totalRamGb, 8);
    });

    test('availableRamGb converts available RAM bytes to decimal GB', () {
      const resources = DeviceResources(availableRamBytes: 3500000000);

      expect(resources.availableRamGb, 3.5);
    });

    test('freeStorageGb converts free storage bytes to decimal GB', () {
      const resources = DeviceResources(freeStorageBytes: 20000000000);

      expect(resources.freeStorageGb, 20);
    });
  });
}
