import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/play_update_repository.dart';

class PlayUpdateButton extends StatefulWidget {
  const PlayUpdateButton({super.key, required this.repository});
  final PlayUpdateRepository repository;

  @override
  State<PlayUpdateButton> createState() => _PlayUpdateButtonState();
}

class _PlayUpdateButtonState extends State<PlayUpdateButton>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check(resumeOnly: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check(resumeOnly: true));
    }
  }

  Future<void> _message(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktualizacja Google Play'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _check({bool resumeOnly = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await widget.repository.check();
      if (!mounted) return;
      if (resumeOnly && status != PlayUpdateStatus.interrupted) return;
      if (status == PlayUpdateStatus.current) {
        await _message('Masz aktualną wersję aplikacji.');
      } else if (status == PlayUpdateStatus.unavailable) {
        await _message(
          'Google Play nie udostępnia teraz aktualizacji dla tego konta.',
        );
      } else {
        final confirmed =
            status == PlayUpdateStatus.interrupted ||
            await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Dostępna jest nowa wersja'),
                    content: const Text(
                      'Czy chcesz zainstalować aktualizację przez Google Play?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Później'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Aktualizuj'),
                      ),
                    ],
                  ),
                ) ==
                true;
        if (confirmed && mounted) await widget.repository.update();
      }
    } on UpdateFailure catch (error) {
      if (!resumeOnly) await _message(error.message);
    } catch (_) {
      if (!resumeOnly) {
        await _message('Nie udało się sprawdzić aktualizacji w Google Play.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _busy ? null : () => _check(),
    style: TextButton.styleFrom(
      textStyle: Theme.of(context).textTheme.labelSmall,
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: const Text('Aktualizuj'),
  );
}
