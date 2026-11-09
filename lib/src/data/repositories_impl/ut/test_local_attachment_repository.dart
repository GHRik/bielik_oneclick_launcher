import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_attachment_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class _TextFile extends Fake implements XFile {
  _TextFile(this.bytes);
  final Uint8List bytes;
  @override
  String get name => 'notatki.txt';
  @override
  Future<int> length() async => bytes.length;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) => Stream.value(bytes);
}

void main() {
  test('Cancelling the picker returns no attachment', () async {
    final repository = LocalAttachmentRepository(selectFile: () async => null);
    expect(await repository.pickTextAttachment(), isNull);
  });
  test(
    'Reads the selected file without opening the platform picker in tests',
    () async {
      final bytes = Uint8List.fromList(utf8.encode('Treść pliku'));
      final repository = LocalAttachmentRepository(
        selectFile: () async => _TextFile(bytes),
      );
      final attachment = (await repository.pickTextAttachment())!;
      expect(attachment.name, 'notatki.txt');
      expect(attachment.text, 'Treść pliku');
      expect(attachment.sizeBytes, bytes.length);
    },
  );
  test('Converts file access errors to a readable failure', () async {
    final repository = LocalAttachmentRepository(
      selectFile: () async => throw StateError('Read failed'),
    );
    await expectLater(
      repository.pickTextAttachment(),
      throwsA(
        isA<AttachmentException>().having(
          (error) => error.failure,
          'failure',
          AttachmentFailure.readFailed,
        ),
      ),
    );
  });
}
