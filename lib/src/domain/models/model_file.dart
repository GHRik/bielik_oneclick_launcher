class ModelFile {
  const ModelFile({
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
  });

  final String name;
  final String url;
  final int sizeBytes;
  final String sha256;
}
