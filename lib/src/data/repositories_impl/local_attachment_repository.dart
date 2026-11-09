import 'package:file_selector/file_selector.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/txt_attachment_decoder.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/attachment_repository.dart';

class LocalAttachmentRepository implements AttachmentRepository {
  LocalAttachmentRepository({Future<XFile?> Function()? selectFile})
    : _selectFile = selectFile ?? _selectTextFile;

  final Future<XFile?> Function() _selectFile;

  static Future<XFile?> _selectTextFile() => openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'TXT',
        extensions: ['txt'],
        mimeTypes: ['text/plain'],
        uniformTypeIdentifiers: ['public.plain-text'],
      ),
    ],
  );

  @override
  Future<TextAttachment?> pickTextAttachment() async {
    try {
      final file = await _selectFile();
      if (file == null) return null;
      if (await file.length() > TxtAttachmentDecoder.maxBytes) {
        throw const AttachmentException(AttachmentFailure.tooLarge);
      }
      final bytes = <int>[];
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length > TxtAttachmentDecoder.maxBytes) {
          throw const AttachmentException(AttachmentFailure.tooLarge);
        }
        bytes.addAll(chunk);
      }
      return const TxtAttachmentDecoder().decode(file.name, bytes);
    } on AttachmentException {
      rethrow;
    } catch (_) {
      throw const AttachmentException(AttachmentFailure.readFailed);
    }
  }
}
