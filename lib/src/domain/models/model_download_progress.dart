class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.bytesPerSecond,
    this.verifying = false,
  });

  final int receivedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final bool verifying;

  double get fraction => (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

class ModelDownloadCancelled implements Exception {}
