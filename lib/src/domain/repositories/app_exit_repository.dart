import 'package:bielik_oneclick_launcher/src/domain/models/app_exit_report.dart';

abstract interface class AppExitRepository {
  Future<AppExitReport?> readPreviousExit();
  Future<void> acknowledge(AppExitReport report);
}

class UnavailableAppExitRepository implements AppExitRepository {
  const UnavailableAppExitRepository();

  @override
  Future<AppExitReport?> readPreviousExit() async => null;

  @override
  Future<void> acknowledge(AppExitReport report) async {}
}
