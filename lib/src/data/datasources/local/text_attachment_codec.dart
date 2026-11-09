import 'dart:convert';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

abstract final class TextAttachmentCodec {
  static String? encode(TextAttachment? attachment) => attachment == null
      ? null
      : jsonEncode({
          'name': attachment.name,
          'text': attachment.text,
          'sizeBytes': attachment.sizeBytes,
        });

  static TextAttachment? decode(Object? value) {
    if (value == null) return null;
    final data = jsonDecode(value as String) as Map<String, dynamic>;
    return TextAttachment(
      name: data['name'] as String,
      text: data['text'] as String,
      sizeBytes: data['sizeBytes'] as int,
    );
  }
}
