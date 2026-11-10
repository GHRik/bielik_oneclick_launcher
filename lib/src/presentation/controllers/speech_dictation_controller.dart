import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

class SpeechDictationController extends ChangeNotifier {
  SpeechDictationController(this.repository, {this.onCompleted});

  final VoidCallback? onCompleted;

  final SpeechRecognitionRepository repository;
  TextEditingController? _target;
  String _prefix = '', _suffix = '', _expected = '';
  bool _writing = false, _disposed = false;
  int _session = 0;
  bool starting = false, listening = false, finishing = false;
  String? error;
  bool get active => _target != null;
  bool get busy => starting || finishing;

  Future<void> toggle(TextEditingController draft) async {
    if (_disposed) return;
    if (active) return stop();
    final session = ++_session;
    _target = draft;
    _expected = draft.text;
    final selection = draft.selection;
    final start = selection.isValid ? selection.start : draft.text.length;
    final end = selection.isValid ? selection.end : draft.text.length;
    _prefix = draft.text.substring(0, start);
    _suffix = draft.text.substring(end);
    draft.addListener(_onDraftEdited);
    error = null;
    starting = true;
    notifyListeners();
    var receivedText = false;
    try {
      await repository.cancel();
      if (!_current(session)) return;
      final started = await repository.start(
        onText: (text) {
          if (!_current(session) || text.trim().isEmpty) return;
          receivedText = true;
          final before = _prefix.isNotEmpty && !RegExp(r'\s$').hasMatch(_prefix)
              ? ' '
              : '';
          final after = _suffix.isNotEmpty && !RegExp(r'^\s').hasMatch(_suffix)
              ? ' '
              : '';
          final spoken = '$_prefix$before$text';
          _expected = '$spoken$after$_suffix';
          _writing = true;
          try {
            draft.value = TextEditingValue(
              text: _expected,
              selection: TextSelection.collapsed(offset: spoken.length),
            );
          } finally {
            _writing = false;
          }
        },
        onDone: () {
          if (!_current(session)) return;
          unawaited(cancel());
          if (receivedText && error == null) onCompleted?.call();
        },
        onError: (failure) {
          if (!_current(session)) return;
          error = switch (failure) {
            SpeechFailure.permissionDenied =>
              'Brak dostępu do mikrofonu. Włącz go w ustawieniach aplikacji.',
            SpeechFailure.unavailable =>
              'Rozpoznawanie mowy jest niedostępne na tym urządzeniu.',
            SpeechFailure.recognition =>
              'Nie udało się rozpoznać mowy. Spróbuj ponownie.',
          };
          unawaited(cancel());
        },
      );
      if (!_current(session)) return;
      starting = false;
      listening = started;
      if (!started) {
        error ??= 'Nie udało się uruchomić dyktowania.';
        await cancel();
      } else {
        notifyListeners();
      }
    } catch (_) {
      if (_current(session)) {
        error = 'Nie udało się uruchomić dyktowania.';
        await cancel();
      }
    }
  }

  bool _current(int session) => !_disposed && session == _session && active;

  void _onDraftEdited() {
    if (!_writing && _target?.text != _expected) unawaited(cancel());
  }

  Future<void> stop() async {
    if (!active || finishing) return;
    if (starting) return cancel();
    listening = false;
    finishing = true;
    notifyListeners();
    try {
      await repository.stop();
    } catch (_) {
      error = 'Nie udało się zakończyć dyktowania.';
      await cancel();
    }
  }

  Future<void> cancel() async {
    ++_session;
    _target?.removeListener(_onDraftEdited);
    _target = null;
    starting = listening = finishing = false;
    if (!_disposed) notifyListeners();
    try {
      await repository.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancel());
    super.dispose();
  }
}
