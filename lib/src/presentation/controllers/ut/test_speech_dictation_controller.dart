import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/speech_dictation_controller.dart';

import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/fake_speech_recognition_repository.dart';

void main() {
  late FakeSpeechRecognitionRepository repository;
  late SpeechDictationController controller;
  late TextEditingController draft;
  setUp(() {
    repository = FakeSpeechRecognitionRepository();
    controller = SpeechDictationController(repository);
    draft = TextEditingController();
  });
  tearDown(() {
    controller.dispose();
    draft.dispose();
  });

  test('Starts listening only after toggling the microphone', () async {
    expect(repository.starts, 0);
    await controller.toggle(draft);
    expect(controller.listening, isTrue);
  });

  test('Replaces partial results instead of duplicating them', () async {
    await controller.toggle(draft);
    repository.text!('Hej');
    repository.text!('Hej Bielik');
    expect(draft.text, 'Hej Bielik');
  });

  test('Preserves the draft when appending speech', () async {
    draft.text = 'Existing';
    await controller.toggle(draft);
    repository.text!('spoken');
    expect(draft.text, 'Existing spoken');
  });

  test('Inserts dictation at the selected text range', () async {
    draft.value = const TextEditingValue(
      text: 'Hello old world',
      selection: TextSelection(baseOffset: 6, extentOffset: 9),
    );
    await controller.toggle(draft);
    repository.text!('new');
    expect(draft.text, 'Hello new world');
  });

  test(
    'Keeps final recognition results received after pressing stop',
    () async {
      await controller.toggle(draft);
      await controller.stop();
      repository.text!('Final answer');
      repository.done!();
      expect(draft.text, 'Final answer');
      expect(controller.active, isFalse);
    },
  );

  test('Stops when the microphone is toggled a second time', () async {
    await controller.toggle(draft);
    await controller.toggle(draft);
    expect(repository.stops, 1);
  });

  test('Manual edits cancel dictation without losing the edit', () async {
    await controller.toggle(draft);
    repository.text!('Spoken');
    draft.text = 'Edited';
    repository.text!('Late words');
    expect(draft.text, 'Edited');
    expect(controller.active, isFalse);
  });

  test('Permission denial preserves the existing draft', () async {
    draft.text = 'Keep';
    await controller.toggle(draft);
    repository.failure!(SpeechFailure.permissionDenied);
    expect(draft.text, 'Keep');
    expect(controller.error, contains('mikrofonu'));
  });

  test('Cancelling during startup ignores a late successful start', () async {
    repository.pendingStart = Completer<bool>();
    final start = controller.toggle(draft);
    await Future<void>.delayed(Duration.zero);
    await controller.cancel();
    repository.pendingStart!.complete(true);
    await start;
    expect(controller.active, isFalse);
  });

  test('Ending a session ignores its late results', () async {
    await controller.toggle(draft);
    final result = repository.text!;
    await controller.cancel();
    result('Late');
    expect(draft.text, isEmpty);
  });

  test('A previous session cannot overwrite a new session', () async {
    await controller.toggle(draft);
    final oldResult = repository.text!;
    await controller.cancel();
    await controller.toggle(draft);
    repository.text!('New');
    oldResult('Old');
    expect(draft.text, 'New');
  });

  test('Disposal ignores recognition callbacks', () async {
    final other = SpeechDictationController(repository);
    await other.toggle(draft);
    other.dispose();
    repository.text!('Late');
    expect(draft.text, isEmpty);
  });
}
