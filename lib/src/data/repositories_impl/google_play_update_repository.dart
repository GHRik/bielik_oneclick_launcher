import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/play_update_repository.dart';

class GooglePlayUpdateRepository implements PlayUpdateRepository {
  @override
  Future<PlayUpdateStatus> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        return PlayUpdateStatus.interrupted;
      }
      if (info.updateAvailability == UpdateAvailability.updateNotAvailable) {
        return PlayUpdateStatus.current;
      }
      return info.updateAvailability == UpdateAvailability.updateAvailable &&
              info.immediateUpdateAllowed
          ? PlayUpdateStatus.available
          : PlayUpdateStatus.unavailable;
    } on PlatformException {
      throw const UpdateFailure(
        'Nie udało się sprawdzić aktualizacji w Google Play. '
        'Sprawdź połączenie i spróbuj ponownie, gdy będziesz online.',
      );
    }
  }

  @override
  Future<PlayUpdateResult> update() async {
    // Play requires fresh update information for every installation attempt.
    final status = await check();
    if (status == PlayUpdateStatus.current) return PlayUpdateResult.completed;
    if (status == PlayUpdateStatus.unavailable) {
      throw const UpdateFailure(
        'Aktualizacja nie jest teraz dostępna w Google Play.',
      );
    }
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.userDeniedUpdate) {
        return PlayUpdateResult.cancelled;
      }
      if (result != AppUpdateResult.success) {
        throw const UpdateFailure(
          'Google Play nie zakończył aktualizacji. Spróbuj ponownie.',
        );
      }
      return PlayUpdateResult.completed;
    } on PlatformException {
      throw const UpdateFailure(
        'Nie udało się uruchomić aktualizacji w Google Play.',
      );
    }
  }
}
