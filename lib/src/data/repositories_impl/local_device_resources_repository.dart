import 'package:flutter/services.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/device_resources_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

class LocalDeviceResourcesRepository implements DeviceResourcesRepository {
  const LocalDeviceResourcesRepository(this._source);

  final DeviceResourcesDataSource _source;

  @override
  Future<DeviceResources> read() async {
    try {
      final values = await _source.read();
      int? bytes(String key) {
        final value = values[key];
        return value is int && value >= 0 ? value : null;
      }

      return DeviceResources(
        totalRamBytes: bytes('totalRamBytes'),
        availableRamBytes: bytes('availableRamBytes'),
        freeStorageBytes: bytes('freeStorageBytes'),
      );
    } on MissingPluginException {
      return const DeviceResources();
    } on PlatformException {
      return const DeviceResources();
    }
  }
}
