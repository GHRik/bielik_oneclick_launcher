import 'package:flutter/services.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_exit_report.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_exit_repository.dart';

class AndroidAppExitRepository implements AppExitRepository {
  const AndroidAppExitRepository({
    this.channel = const MethodChannel('bielik/app_exit'),
  });

  final MethodChannel channel;

  @override
  Future<AppExitReport?> readPreviousExit() async {
    final data = await channel.invokeMapMethod<String, dynamic>(
      'readPreviousExit',
    );
    if (data == null) return null;
    return AppExitReport(
      id: data['id'] as String,
      lowMemory: data['lowMemory'] as bool,
      code: data['code'] as String,
    );
  }

  @override
  Future<void> acknowledge(AppExitReport report) =>
      channel.invokeMethod<void>('acknowledgeExit', report.id);
}
