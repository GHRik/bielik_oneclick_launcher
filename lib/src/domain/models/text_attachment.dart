import 'dart:convert';

class TextAttachment {
  const TextAttachment({
    required this.name,
    required this.text,
    required this.sizeBytes,
  });

  final String name;
  final String text;
  final int sizeBytes;
  int get contentSizeBytes =>
      utf8.encode(name).length + utf8.encode(text).length;
}

enum AttachmentFailure {
  unsupportedType,
  tooLarge,
  invalidEncoding,
  empty,
  readFailed,
}

class AttachmentException implements Exception {
  const AttachmentException(this.failure);
  final AttachmentFailure failure;
}
