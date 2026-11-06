import 'package:flutter/services.dart';

class StatisticsDataSource {
  const StatisticsDataSource();

  static const _channel = MethodChannel('bielik/device_resources');

  Future<Map<String, dynamic>> read() async {
    try {
      return await _channel.invokeMapMethod<String, dynamic>('statistics') ??
          {};
    } on MissingPluginException {
      return {};
    } on PlatformException {
      return {};
    }
  }
}
