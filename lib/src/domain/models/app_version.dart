class AppVersion {
  const AppVersion({
    required this.name,
    required this.build,
    this.installedFromGooglePlay = false,
  });
  final String name;
  final int build;
  final bool installedFromGooglePlay;

  bool usesGooglePlayUpdates({required bool apkUpdatesEnabled}) =>
      installedFromGooglePlay || !apkUpdatesEnabled;
}
