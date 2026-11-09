import 'dart:convert';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title = 'Nowa rozmowa',
    this.draft = '',
    this.draftAttachment,
  });

  final int id;
  final String title;
  final String draft;
  final TextAttachment? draftAttachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get contentSizeBytes =>
      utf8.encode(title).length +
      utf8.encode(draft).length +
      (draftAttachment?.contentSizeBytes ?? 0);

  Conversation copyWith({
    String? title,
    String? draft,
    DateTime? updatedAt,
    TextAttachment? draftAttachment,
    bool clearDraftAttachment = false,
  }) => Conversation(
    id: id,
    title: title ?? this.title,
    draft: draft ?? this.draft,
    draftAttachment: clearDraftAttachment
        ? null
        : draftAttachment ?? this.draftAttachment,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
