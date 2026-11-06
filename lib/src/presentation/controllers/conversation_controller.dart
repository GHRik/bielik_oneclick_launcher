import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';

class ConversationController extends ChangeNotifier {
  ConversationController(
    Conversation conversation, {
    required List<ChatMessage> messages,
    required this.onDraftChanged,
  }) : _conversation = conversation,
       controller = InMemoryChatController(
         messages: messages.map(_viewMessage).toList(),
       ),
       draft = TextEditingController(text: conversation.draft),
       hasMessages = messages.isNotEmpty,
       _messageContentBytes = messages.fold(0, (total, message) => total + message.contentSizeBytes) {
    draft.addListener(_draftChanged);
  }

  Conversation _conversation;
  final InMemoryChatController controller;
  final TextEditingController draft;
  final ValueChanged<String> onDraftChanged;
  bool hasMessages;
  int _messageContentBytes;
  int _draftRevision = 0;
  bool _suppressDraftChanges = false;

  Conversation get conversation => _conversation;
  int get id => _conversation.id;
  String get title => _conversation.title;
  int get draftRevision => _draftRevision;
  int get contentSizeBytes => _conversation.contentSizeBytes + _messageContentBytes;

  static TextMessage _viewMessage(ChatMessage message) => TextMessage(
        id: message.id,
        authorId: message.authorId,
        createdAt: message.createdAt,
        text: message.text,
      );

  void _draftChanged() {
    if (_suppressDraftChanges || draft.text == _conversation.draft) return;
    _draftRevision++;
    _conversation = _conversation.copyWith(draft: draft.text);
    onDraftChanged(draft.text);
    notifyListeners();
  }

  Future<void> addMessage(
    ChatMessage message, {
    required int submittedDraftRevision,
    String? title,
  }) async {
    await controller.insertMessage(_viewMessage(message));
    hasMessages = true;
    _messageContentBytes += message.contentSizeBytes;
    _conversation = _conversation.copyWith(
      title: title,
      updatedAt: message.createdAt,
    );
    if (_draftRevision == submittedDraftRevision) {
      _suppressDraftChanges = true;
      draft.clear();
      _suppressDraftChanges = false;
      _draftRevision++;
      _conversation = _conversation.copyWith(draft: '');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    draft.removeListener(_draftChanged);
    controller.dispose();
    draft.dispose();
    super.dispose();
  }
}
