enum PlayUpdateStatus { current, available, interrupted, unavailable }

enum PlayUpdateResult { completed, cancelled }

abstract class PlayUpdateRepository {
  Future<PlayUpdateStatus> check();
  Future<PlayUpdateResult> update();
}
