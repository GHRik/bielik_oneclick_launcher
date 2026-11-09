import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

class FakeSpeechRecognitionRepository implements SpeechRecognitionRepository {
  void Function(String)? text;
  void Function()? done;
  void Function(SpeechFailure)? failure;
  Completer<bool>? pendingStart;
  bool available = true;
  int starts = 0, stops = 0, cancellations = 0;

  @override
  Future<bool> start({
    required void Function(String text) onText,
    required void Function() onDone,
    required void Function(SpeechFailure failure) onError,
  }) async {
    ++starts;
    text = onText;
    done = onDone;
    failure = onError;
    return await (pendingStart?.future ?? Future.value(available));
  }

  @override
  Future<void> stop() async {
    ++stops;
  }

  @override
  Future<void> cancel() async {
    ++cancellations;
  }
}
