class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.build,
    required this.url,
    required this.sha256,
    required this.bytes,
  });
  final String version;
  final int build;
  final Uri url;
  final String sha256;
  final int bytes;
}

class UpdateFailure implements Exception {
  const UpdateFailure(this.message);
  final String message;
}
