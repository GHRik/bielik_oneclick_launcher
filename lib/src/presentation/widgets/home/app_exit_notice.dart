import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/app_exit_repository.dart';

class AppExitNotice extends StatefulWidget {
  const AppExitNotice({
    super.key,
    required this.repository,
    required this.child,
  });

  final AppExitRepository repository;
  final Widget child;

  @override
  State<AppExitNotice> createState() => _AppExitNoticeState();
}

class _AppExitNoticeState extends State<AppExitNotice> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final report = await widget.repository.readPreviousExit();
      if (!mounted || report == null) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Poprzednie zamknięcie aplikacji'),
            content: SingleChildScrollView(
              child: Text(
                report.lowMemory
                    ? 'Aplikacja została zamknięta z powodu braku pamięci RAM. '
                          'Wybrany model lub duży kontekst może przekraczać możliwości telefonu. '
                          'Spróbuj mniejszego modelu albo zmniejsz kontekst.'
                    : 'Poprzednie działanie aplikacji zostało nieoczekiwanie zakończone. '
                          'Android nie potwierdził braku pamięci RAM.\n\n'
                          'Kod diagnostyczny: ${report.code}.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
      await widget.repository.acknowledge(report);
    } catch (_) {
      // Diagnostics must not prevent starting or using the application.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
