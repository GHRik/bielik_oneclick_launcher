import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';

class SqliteChatDataSource {
  const SqliteChatDataSource(this.database);

  final AppDatabase database;

  Future<List<Map<String, Object?>>> getConversations() async {
    final connection = await database.open();
    return connection.query(
      'conversations',
      orderBy: 'last_used_at DESC, id DESC',
    );
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
    return connection.transaction((transaction) async {
      final id = await transaction.insert('conversations', values);
      await _markUsed(transaction, id, timestamp);
      return {...values, 'id': id};
    });
  }

  Future<void> markConversationUsed(int conversationId) async {
    final connection = await database.open();
    await _markUsed(
      connection,
      conversationId,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  Future<void> _markUsed(
    DatabaseExecutor connection,
    int conversationId,
    int timestamp,
  ) async {
    final count = await connection.rawUpdate(
      'UPDATE conversations SET last_used_at = MAX(?, '
      '(SELECT COALESCE(MAX(last_used_at), 0) + 1 FROM conversations)) '
      'WHERE id = ?',
      [timestamp, conversationId],
    );
    if (count != 1) throw StateError('Nie znaleziono rozmowy.');
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
    required bool clearDraft,
    String? attachment,
  }) async {
    final connection = await database.open();
    return connection.transaction((transaction) async {
      final id =
          (await transaction.rawQuery(
                'SELECT lower(hex(randomblob(16))) AS id',
              )).single['id']!
              as String;
      final message = <String, Object?>{
        'id': id,
        'conversation_id': conversationId,
        'author_id': authorId,
        'text': text,
        'attachment': attachment,
        'created_at': timestamp,
      };
      await transaction.insert('messages', message);
      await transaction.update(
        'conversations',
        {
          if (clearDraft) 'draft': '',
          if (clearDraft) 'draft_attachment': null,
          'updated_at': timestamp,
          'title': ?conversationTitle,
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
      return message;
    });
  }

  Future<void> updateMessage(String id, String text) async {
    final connection = await database.open();
    final count = await connection.update(
      'messages',
      {'text': text},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Nie znaleziono wiadomości do zapisu.');
  }

  Future<void> saveDraft(int conversationId, String draft) async {
    final connection = await database.open();
    await connection.update(
      'conversations',
      {
        'draft': draft,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> saveDraftAttachment(
    int conversationId,
    String? attachment,
  ) async {
    final connection = await database.open();
    await connection.update(
      'conversations',
      {'draft_attachment': attachment},
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
