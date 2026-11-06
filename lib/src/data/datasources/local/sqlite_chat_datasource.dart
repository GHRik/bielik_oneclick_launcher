import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class SqliteChatDataSource {
  const SqliteChatDataSource(this.database);

  final AppDatabase database;

  Future<List<Map<String, Object?>>> getConversations() async {
    final connection = await database.open();
    return connection.query('conversations', orderBy: 'created_at DESC, id DESC');
  }

  Future<Map<String, Object?>> createConversation({
    required String title,
    required int timestamp,
  }) async {
    final connection = await database.open();
    final values = <String, Object?>{
      'title': title,
      'draft': '',
      'created_at': timestamp,
      'updated_at': timestamp,
    };
    final id = await connection.insert('conversations', values);
    return {...values, 'id': id};
  }

  Future<List<Map<String, Object?>>> getMessages(int conversationId) async {
    final connection = await database.open();
    return connection.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC, rowid ASC',
    );
  }

  Future<Map<String, Object?>> addMessage({
    required int conversationId,
    required String authorId,
    required String text,
    required int timestamp,
    String? conversationTitle,
  }) async {
    final connection = await database.open();
    return connection.transaction((transaction) async {
      final id = (await transaction.rawQuery(
        'SELECT lower(hex(randomblob(16))) AS id',
      )).single['id']! as String;
      final message = <String, Object?>{
        'id': id,
        'conversation_id': conversationId,
        'author_id': authorId,
        'text': text,
        'created_at': timestamp,
      };
      await transaction.insert('messages', message);
      await transaction.update(
        'conversations',
        {
          'draft': '',
          'updated_at': timestamp,
          'title': ?conversationTitle,
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
      return message;
    });
  }

  Future<void> saveDraft(int conversationId, String draft) async {
    final connection = await database.open();
    await connection.update(
      'conversations',
      {'draft': draft, 'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteConversation(int conversationId) async {
    final connection = await database.open();
    await connection.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }
}
