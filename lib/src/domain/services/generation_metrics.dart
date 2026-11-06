class GenerationMetrics {
  double? firstResponseSeconds;
  final Stopwatch _request = Stopwatch();
  bool _first = false;

  void begin() {
    _request
      ..reset()
      ..start();
    _first = false;
  }

  void firstText() {
    if (_first) return;
    _first = true;
    firstResponseSeconds = _request.elapsedMicroseconds / 1000000;
  }
}
