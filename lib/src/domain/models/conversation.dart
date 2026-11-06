class Conversation {
  const Conversation({required this.id, this.title = 'Nowa rozmowa'});

  final int id;
  final String title;

  Conversation copyWith({String? title}) =>
      Conversation(id: id, title: title ?? this.title);
}
