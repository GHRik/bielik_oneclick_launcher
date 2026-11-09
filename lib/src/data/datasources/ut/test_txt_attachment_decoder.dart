import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/txt_attachment_decoder.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

void main() {
  const decoder = TxtAttachmentDecoder();
  Matcher fails(AttachmentFailure failure) => throwsA(
    isA<AttachmentException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );

  test('Preserves Polish text, emoji and line breaks', () {
    const text = 'Zażółć 🙂\n\nDrugi akapit';
    expect(decoder.decode('plik.txt', utf8.encode(text)).text, text);
  });
  test('Accepts a UTF-8 byte order mark', () {
    expect(decoder.decode('plik.txt', [239, 187, 191, 65]).text, 'A');
  });
  test('Accepts uppercase file extensions', () {
    expect(decoder.decode('PLIK.TXT', [65]).name, 'PLIK.TXT');
  });
  test('Rejects unsupported file types', () {
    expect(
      () => decoder.decode('plik.pdf', [65]),
      fails(AttachmentFailure.unsupportedType),
    );
  });
  test('Rejects files over the byte limit', () {
    expect(
      () => decoder.decode(
        'plik.txt',
        List.filled(TxtAttachmentDecoder.maxBytes + 1, 65),
      ),
      fails(AttachmentFailure.tooLarge),
    );
  });
  test('Rejects invalid UTF-8 instead of replacing characters', () {
    expect(
      () => decoder.decode('plik.txt', [255]),
      fails(AttachmentFailure.invalidEncoding),
    );
  });
  test('Rejects binary content renamed to TXT', () {
    expect(
      () => decoder.decode('plik.txt', [0, 1, 2]),
      fails(AttachmentFailure.invalidEncoding),
    );
  });
  test('Rejects empty or whitespace-only files', () {
    expect(
      () => decoder.decode('plik.txt', utf8.encode(' \n ')),
      fails(AttachmentFailure.empty),
    );
  });
}
