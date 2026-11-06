import 'package:flutter/foundation.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

class DeviceResourcesController extends ChangeNotifier {
  DeviceResourcesController(this._repository);

  final DeviceResourcesRepository? _repository;
  DeviceResources resources = const DeviceResources();
  bool _disposed = false;
  Future<void>? _pending;

  Future<void> refresh() =>
      _pending ??= _read().whenComplete(() => _pending = null);

  Future<void> _read() async {
    try {
      final result = await _repository?.read() ?? const DeviceResources();
      if (_disposed) return;
      resources = result;
    } catch (_) {
      if (_disposed) return;
      resources = const DeviceResources();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
