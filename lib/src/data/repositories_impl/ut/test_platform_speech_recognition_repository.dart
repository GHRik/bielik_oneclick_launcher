import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/platform_speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PlatformSpeechRecognitionRepository repository;
  late List<MethodCall> calls;
  late List<SpeechFailure> errors;
  late List<String> words;
  bool available = true;
  bool permission = true;
  Completer<bool>? initialization;

  Future<void> event(String method, dynamic arguments) async {
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) {},
    );
  }

  Future<bool> start() =>
      repository.start(onText: words.add, onDone: () {}, onError: errors.add);

  setUp(() {
    calls = [];
    errors = [];
    words = [];
    available = permission = true;
    initialization = null;
    repository = PlatformSpeechRecognitionRepository(
      speech: SpeechToText.withMethodChannel(),
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => initialization?.future ?? Future.value(available),
        'has_permission' => permission,
        'listen' => true,
        _ => null,
      };
    });
  });
  tearDown(() async {
    await repository.cancel();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('Does not initialize or request access before start', () {
    expect(calls, isEmpty);
  });

  test('Starts recognition in dictation mode', () async {
    await start();
    final arguments =
        calls.singleWhere((call) => call.method == 'listen').arguments as Map;
    expect(arguments['listenMode'], ListenMode.dictation.index);
  });

  test('Reports permission denial without listening', () async {
    available = permission = false;
    await start();
    expect(errors, [SpeechFailure.permissionDenied]);
    expect(calls.where((call) => call.method == 'listen'), isEmpty);
  });

  test('Reports an unavailable recognition service', () async {
    available = false;
    await start();
    expect(errors, [SpeechFailure.unavailable]);
  });

  test('Forwards recognized text', () async {
    await start();
    await event(
      'textRecognition',
      jsonEncode({
        'alternates': [
          {'recognizedWords': 'Hej Bielik', 'confidence': 1.0},
        ],
        'resultType': 0,
      }),
    );
    expect(words, ['Hej Bielik']);
  });

  test(
    'Cancellation during permission initialization prevents listening',
    () async {
      initialization = Completer<bool>();
      final starting = start();
      final cancelling = repository.cancel();
      initialization!.complete(true);
      await starting;
      await cancelling;
      expect(calls.where((call) => call.method == 'listen'), isEmpty);
    },
  );

  test('Rechecks permission before every recording', () async {
    await start();
    await repository.cancel();
    permission = false;
    await start();
    expect(errors.last, SpeechFailure.permissionDenied);
    expect(calls.where((call) => call.method == 'listen').length, 1);
  });
}
