import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/statistic_series.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/statistics_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/sampling_statistics_repository.dart';

class StatisticsController extends ChangeNotifier {
  StatisticsController(this._repository) : series = _repository.getSeries();

  final StatisticsRepository _repository;
  List<StatisticSeries> series;
  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;
  bool _running = false;
  int _epoch = 0;

  void start() {
    if (_disposed || _running) return;
    _running = true;
    _epoch++;
    unawaited(refresh());
    if (_repository is SamplingStatisticsRepository) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(refresh()),
      );
    }
  }

  Future<void> refresh() async {
    if (_reading || _disposed) return;
    _reading = true;
    final epoch = _epoch;
    try {
      final repo = _repository;
      final result = repo is SamplingStatisticsRepository
          ? await repo.sample()
          : repo.getSeries();
      if (_disposed || epoch != _epoch) return;
      series = result;
      notifyListeners();
    } finally {
      _reading = false;
    }
  }

  void pause() {
    _running = false;
    _epoch++;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    pause();
    _disposed = true;
    super.dispose();
  }
}
