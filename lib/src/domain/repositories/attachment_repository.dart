import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

abstract interface class AttachmentRepository {
  Future<TextAttachment?> pickTextAttachment();
}
