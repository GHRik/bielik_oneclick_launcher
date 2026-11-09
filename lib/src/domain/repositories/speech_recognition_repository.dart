enum SpeechFailure { permissionDenied, unavailable, recognition }

abstract interface class SpeechRecognitionRepository {
  Future<bool> start({
    required void Function(String text) onText,
    required void Function() onDone,
    required void Function(SpeechFailure failure) onError,
  });
  Future<void> stop();
  Future<void> cancel();
}
