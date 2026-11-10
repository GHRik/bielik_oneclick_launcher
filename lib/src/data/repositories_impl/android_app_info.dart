import 'package:flutter/services.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';

class AndroidAppInfo {
  static const channel = MethodChannel('bielik/app_info');

  static Future<AppVersion?> version() async {
    try {
      final data = await channel.invokeMapMethod<String, dynamic>('version');
      if (data == null) return null;
      return AppVersion(
        name: data['name'] as String,
        build: data['build'] as int,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
