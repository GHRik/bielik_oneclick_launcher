import 'dart:convert';

class Conversation {
  const Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title = 'Nowa rozmowa',
    this.draft = '',
  });

  final int id;
  final String title;
  final String draft;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get contentSizeBytes => utf8.encode(title).length + utf8.encode(draft).length;

  Conversation copyWith({String? title, String? draft, DateTime? updatedAt}) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        draft: draft ?? this.draft,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
