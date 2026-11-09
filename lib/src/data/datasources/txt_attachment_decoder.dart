import 'dart:convert';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class TxtAttachmentDecoder {
  const TxtAttachmentDecoder();
  static const maxBytes = 64 * 1024;

  TextAttachment decode(String name, List<int> bytes) {
    if (!name.toLowerCase().endsWith('.txt')) {
      throw const AttachmentException(AttachmentFailure.unsupportedType);
    }
    if (bytes.length > maxBytes) {
      throw const AttachmentException(AttachmentFailure.tooLarge);
    }
    late String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const AttachmentException(AttachmentFailure.invalidEncoding);
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(text)) {
      throw const AttachmentException(AttachmentFailure.invalidEncoding);
    }
    if (text.trim().isEmpty) {
      throw const AttachmentException(AttachmentFailure.empty);
    }
    return TextAttachment(name: name, text: text, sizeBytes: bytes.length);
  }
}
