import 'package:speech_to_text/speech_to_text.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

class PlatformSpeechRecognitionRepository
    implements SpeechRecognitionRepository {
  PlatformSpeechRecognitionRepository({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  Future<bool>? _initialization;
  Future<void> _cleanup = Future.value();
  void Function()? _onDone;
  void Function(SpeechFailure)? _onError;
  int _session = 0;

  @override
  Future<bool> start({
    required void Function(String text) onText,
    required void Function() onDone,
    required void Function(SpeechFailure failure) onError,
  }) async {
    final session = ++_session;
    await _cleanup;
    if (session != _session) return false;
    _onDone = onDone;
    _onError = onError;
    try {
      final available = await (_initialization ??= _speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
        onStatus: (status) {
          if (status == SpeechToText.doneStatus) _onDone?.call();
        },
        onError: (error) => _onError?.call(
          error.errorMsg.contains('permission')
              ? SpeechFailure.permissionDenied
              : SpeechFailure.recognition,
        ),
      ));
      if (session != _session) return false;
      if (!available) {
        _initialization = null;
        onError(
          await _speech.hasPermission
              ? SpeechFailure.unavailable
              : SpeechFailure.permissionDenied,
        );
        return false;
      }
      if (!await _speech.hasPermission) {
        if (session == _session) onError(SpeechFailure.permissionDenied);
        return false;
      }
      if (session != _session) return false;
      await _speech.listen(
        onResult: (result) {
          if (session == _session) onText(result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
      return session == _session;
    } catch (_) {
      if (session == _session) onError(SpeechFailure.unavailable);
      return false;
    }
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() {
    ++_session;
    _onDone = null;
    _onError = null;
    return _cleanup = _cleanup.then((_) async {
      try {
        if (await _initialization == true) await _speech.cancel();
      } catch (_) {
        _initialization = null;
      }
    });
  }
}
