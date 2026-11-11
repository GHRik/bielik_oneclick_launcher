import 'package:flutter/foundation.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

class DeviceResourcesController extends ChangeNotifier {
  DeviceResourcesController(this._repository);

  final DeviceResourcesRepository? _repository;
  DeviceResources resources = const DeviceResources();
  bool _disposed = false;
  Future<void>? _pending;
  bool _repeat = false;

  /// A request that arrives during a read repeats the read once it ends, so
  /// the result is never older than the latest request.
  Future<void> refresh() {
    final pending = _pending;
    if (pending != null) {
      _repeat = true;
      return pending;
    }
    return _pending = _readLatest().whenComplete(() => _pending = null);
  }

  Future<void> _readLatest() async {
    do {
      _repeat = false;
      await _read();
    } while (_repeat && !_disposed);
  }

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
