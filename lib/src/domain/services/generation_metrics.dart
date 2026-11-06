class GenerationMetrics {
  double? firstResponseSeconds;
  int? completedTokens;
  int _total = 0;
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

  void complete({required int tokens, required Duration? duration}) {
    if (tokens < 0) return;
    _total += tokens;
    completedTokens = _total;
  }
}
