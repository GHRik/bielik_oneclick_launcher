import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/conversation.dart';

class ConversationController extends ChangeNotifier {
  ConversationController(
    Conversation conversation, {
    required List<ChatMessage> messages,
    required this.onDraftChanged,
    this.onAttachmentChanged,
  }) : _conversation = conversation,
       _messages = List.of(messages),
       controller = InMemoryChatController(
         messages: messages.map(_viewMessage).toList(),
       ),
       draft = TextEditingController(text: conversation.draft),
       hasMessages = messages.isNotEmpty,
       _messageContentBytes = messages.fold(
         0,
         (total, message) => total + message.contentSizeBytes,
       ) {
    draft.addListener(_draftChanged);
  }

  Conversation _conversation;
  final List<ChatMessage> _messages;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  final InMemoryChatController controller;
  final TextEditingController draft;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<TextAttachment?>? onAttachmentChanged;
  int _attachmentRevision = 0;
  int get attachmentRevision => _attachmentRevision;
  TextAttachment? get attachment => _conversation.draftAttachment;

  void setAttachment(TextAttachment? value) {
    _attachmentRevision++;
    _conversation = _conversation.copyWith(
      draftAttachment: value,
      clearDraftAttachment: value == null,
    );
    onAttachmentChanged?.call(value);
    notifyListeners();
  }

  bool _textActionsOffered = false;
  bool get offersTextActions =>
      _textActionsOffered && draft.text.trim().isNotEmpty;

  void offerTextActions() {
    if (draft.text.trim().isEmpty) return;
    _textActionsOffered = true;
    notifyListeners();
  }

  bool hasMessages;
  int _messageContentBytes;
  int _draftRevision = 0;
  bool _suppressDraftChanges = false;

  Conversation get conversation => _conversation;
  int get id => _conversation.id;
  String get title => _conversation.title;
  int get draftRevision => _draftRevision;
  int get contentSizeBytes =>
      _conversation.contentSizeBytes + _messageContentBytes;

  static TextMessage _viewMessage(ChatMessage message) => TextMessage(
    id: message.id,
    authorId: message.authorId,
    createdAt: message.createdAt,
    text: message.text,
  );

  void _draftChanged() {
    if (_suppressDraftChanges || draft.text == _conversation.draft) return;
    _draftRevision++;
    if (draft.text.trim().isEmpty) _textActionsOffered = false;
    _conversation = _conversation.copyWith(draft: draft.text);
    onDraftChanged(draft.text);
    notifyListeners();
  }

  Future<void> addMessage(
    ChatMessage message, {
    int? submittedDraftRevision,
    int? submittedAttachmentRevision,
    String? title,
  }) async {
    await controller.insertMessage(_viewMessage(message));
    _messages.add(message);
    hasMessages = true;
    _messageContentBytes += message.contentSizeBytes;
    _conversation = _conversation.copyWith(
      title: title,
      updatedAt: message.createdAt,
    );
    if (_attachmentRevision == submittedAttachmentRevision) {
      _attachmentRevision++;
      _conversation = _conversation.copyWith(clearDraftAttachment: true);
    }
    if (_draftRevision == submittedDraftRevision) {
      _suppressDraftChanges = true;
      draft.clear();
      _textActionsOffered = false;
      _suppressDraftChanges = false;
      _draftRevision++;
      _conversation = _conversation.copyWith(draft: '');
    }
    notifyListeners();
  }

  Future<void> updateMessage(String id, String text) async {
    final index = _messages.indexWhere((message) => message.id == id);
    if (index < 0) return;
    final old = _messages[index];
    final updated = ChatMessage(
      id: old.id,
      conversationId: old.conversationId,
      authorId: old.authorId,
      text: text,
      createdAt: old.createdAt,
      attachment: old.attachment,
    );
    await controller.updateMessage(_viewMessage(old), _viewMessage(updated));
    _messages[index] = updated;
    _messageContentBytes += updated.contentSizeBytes - old.contentSizeBytes;
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
