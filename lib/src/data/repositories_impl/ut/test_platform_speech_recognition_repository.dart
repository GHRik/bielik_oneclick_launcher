import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/platform_speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

class _Speech extends Fake implements SpeechToText {
  bool available = true, permission = true;
  int initializations = 0, listens = 0;
  Completer<bool>? pendingInitialization;
  SpeechResultListener? result;
  SpeechListenOptions? options;
  List<SpeechConfigOption>? configuration;

  @override
  Future<bool> get hasPermission async => permission;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    ++initializations;
    configuration = options;
    return await (pendingInitialization?.future ?? Future.value(available));
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    ++listens;
    result = onResult;
    options = listenOptions;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}

  void recognize(String text) =>
      result!(SpeechRecognitionResult([SpeechRecognitionWords(text, null, 1.0)], 0));
}

void main() {
  late _Speech speech;
  late PlatformSpeechRecognitionRepository repository;
  late List<SpeechFailure> errors;
  late List<String> words;

  Future<bool> start() =>
      repository.start(onText: words.add, onDone: () {}, onError: errors.add);

  setUp(() {
    speech = _Speech();
    repository = PlatformSpeechRecognitionRepository(speech: speech);
    errors = [];
    words = [];
  });
  tearDown(() => repository.cancel());

  test('Does not initialize or request access before start', () {
    expect(speech.initializations, 0);
  });

  test('Starts recognition in dictation mode', () async {
    await start();
    expect(speech.options!.listenMode, ListenMode.dictation);
  });

  test(
    'Disables Bluetooth access without requesting extra permissions',
    () async {
      await start();
      expect(speech.configuration, contains(SpeechToText.androidNoBluetooth));
    },
  );

  test('Reports permission denial without listening', () async {
    speech.available = speech.permission = false;
    await start();
    expect(errors, [SpeechFailure.permissionDenied]);
    expect(speech.listens, 0);
  });

  test('Reports an unavailable recognition service', () async {
    speech.available = false;
    await start();
    expect(errors, [SpeechFailure.unavailable]);
  });

  test('Forwards recognized text', () async {
    await start();
    speech.recognize('Hej Bielik');
    expect(words, ['Hej Bielik']);
  });

  test(
    'Cancellation during permission initialization prevents listening',
    () async {
      speech.pendingInitialization = Completer<bool>();
      final starting = start();
      await Future<void>.delayed(Duration.zero);
      final cancelling = repository.cancel();
      speech.pendingInitialization!.complete(true);
      await starting;
      await cancelling;
      expect(speech.listens, 0);
    },
  );

  test('Rechecks permission before every recording', () async {
    await start();
    await repository.cancel();
    speech.permission = false;
    await start();
    expect(errors.last, SpeechFailure.permissionDenied);
    expect(speech.listens, 1);
  });

  test('Ignores recognition results delivered after cancellation', () async {
    await start();
    await repository.cancel();
    speech.recognize('Late text');
    expect(words, isEmpty);
  });
}
