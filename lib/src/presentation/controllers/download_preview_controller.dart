import 'dart:async';

import 'package:flutter/foundation.dart';

class DownloadPreviewController extends ChangeNotifier {
  static const double _speedMb = 20;
  Timer? _timer;
  double _downloadedMb = 0;
  double _totalMb = 1;
  bool _visible = false;
  bool _complete = false;

  bool get isRunning => _timer?.isActive ?? false;
  bool get visible => _visible;
  bool get complete => _complete;
  double get progress => (_downloadedMb / _totalMb).clamp(0.0, 1.0);
  int get percent => (progress * 100).floor();
  String get speed => isRunning ? _speedMb.toStringAsFixed(1) : '0,0';

  String get remainingTime {
    final seconds = ((_totalMb - _downloadedMb) / _speedMb).ceil();
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }

  void start(double totalMb) {
    _timer?.cancel();
    _totalMb = totalMb;
    _downloadedMb = 0;
    _visible = true;
    _complete = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _downloadedMb = (_downloadedMb + _speedMb).clamp(0.0, _totalMb);
      if (progress >= 1) {
        timer.cancel();
        _complete = true;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _visible = false;
    _complete = false;
    _downloadedMb = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
