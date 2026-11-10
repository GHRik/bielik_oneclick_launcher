import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_update_repository.dart';

class AppUpdateButton extends StatelessWidget {
  const AppUpdateButton({
    super.key,
    required this.repository,
    required this.version,
  });
  final AppUpdateRepository repository;
  final AppVersion version;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: const Size(88, 36),
      textStyle: Theme.of(context).textTheme.labelSmall,
    ),
    child: const Text('Aktualizuj'),
    onPressed: () => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(repository: repository, version: version),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.repository, required this.version});
  final AppUpdateRepository repository;
  final AppVersion version;
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  AppUpdate? _update;
  String? _path;
  String _message = 'Sprawdzanie aktualizacji…';
  bool _busy = true;
  bool _downloading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final update = await widget.repository.check(widget.version.build);
      if (!mounted) return;
      setState(() {
        _update = update;
        _busy = false;
        _message = update == null
            ? 'Masz najnowszą wersję aplikacji.'
            : 'Dostępna jest wersja ${update.version}. Czy chcesz ją pobrać i zainstalować?';
      });
    } catch (error) {
      _error(error);
    }
  }

  void _error(Object error) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _downloading = false;
      _message = error is UpdateFailure
          ? error.message
          : 'Nie udało się zaktualizować aplikacji.';
    });
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _downloading = true;
      _message = 'Pobieranie aktualizacji…';
    });
    try {
      _path = await widget.repository.download(_update!, (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            if (progress >= 1) _message = 'Weryfikowanie pobranego APK…';
          });
        }
      });
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _message = 'Sprawdzanie APK i otwieranie instalatora…';
      });
      await _install();
    } catch (error) {
      _error(error);
    }
  }

  Future<void> _install() async {
    setState(() => _busy = true);
    try {
      final opened = await widget.repository.install(_path!);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = opened
            ? 'Instalator Androida został otwarty. Zatwierdź w nim aktualizację.'
            : 'Zezwól tej aplikacji na instalowanie aktualizacji w ustawieniach Androida. Potem wróć i naciśnij „Zainstaluj”.';
      });
    } catch (error) {
      _error(error);
    }
  }

  @override
  void dispose() {
    widget.repository.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Aktualizacja aplikacji'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_message),
          if (_busy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _downloading ? _progress : null),
            if (_downloading) Text('${(_progress * 100).floor()}%'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.repository.cancel();
            Navigator.of(context).pop();
          },
          child: Text(_busy ? 'Anuluj' : 'Zamknij'),
        ),
        if (!_busy && _path != null)
          FilledButton(onPressed: _install, child: const Text('Zainstaluj'))
        else if (!_busy && _update != null)
          FilledButton(
            onPressed: _download,
            child: const Text('Pobierz i zainstaluj'),
          ),
      ],
    ),
  );
}
