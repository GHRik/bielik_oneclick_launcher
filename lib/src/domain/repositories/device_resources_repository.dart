import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';

abstract interface class DeviceResourcesRepository {
  Future<DeviceResources> read();
}
