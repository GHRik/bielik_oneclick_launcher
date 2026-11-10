import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';

abstract class AppUpdateRepository {
  Future<AppUpdate?> check(int installedBuild);
  Future<String> download(AppUpdate update, void Function(double) onProgress);
  Future<bool> install(String path);
  void cancel();
}
