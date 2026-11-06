import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DeviceResourcesDataSource {
  const DeviceResourcesDataSource();

  static const channel = MethodChannel('bielik/device_resources');

  Future<Map<String, dynamic>> read() async {
    final directory = await getApplicationSupportDirectory();
    return await channel.invokeMapMethod<String, dynamic>('read', {
          'storagePath': directory.path,
        }) ??
        {};
  }
}
