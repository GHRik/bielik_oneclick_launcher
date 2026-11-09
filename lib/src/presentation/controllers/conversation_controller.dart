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
  ({ChatMessage message, String draft, bool offersActions})? _pendingSubmission;
  int _pendingSequence = 0;
  List<ChatMessage> get displayedMessages => [
    ..._messages,
    ?_pendingSubmission?.message,
  ];

  Future<void> showPendingMessage(
    String text,
    TextAttachment? attachment,
  ) async {
    if (_pendingSubmission != null) return;
    final message = ChatMessage(
      id: 'pending-$id-${_pendingSequence++}',
      conversationId: id,
      authorId: ChatAuthors.user,
      text: text,
      attachment: attachment,
      createdAt: DateTime.now(),
    );
    _pendingSubmission = (
      message: message,
      draft: draft.text.isEmpty && attachment == null ? text : draft.text,
      offersActions: _textActionsOffered,
    );
    _suppressDraftChanges = true;
    draft.clear();
    _suppressDraftChanges = false;
    _textActionsOffered = false;
    _conversation = _conversation.copyWith(
      draft: '',
      clearDraftAttachment: true,
    );
    await controller.insertMessage(_viewMessage(message));
    notifyListeners();
  }

  Future<bool> restorePendingMessage() async {
    final pending = _pendingSubmission;
    if (pending == null) return false;
    _pendingSubmission = null;
    await controller.removeMessage(_viewMessage(pending.message));
    final nextDraft = draft.text;
    draft.text = [
      pending.draft,
      nextDraft,
    ].where((text) => text.isNotEmpty).join('\n\n');
    draft.selection = TextSelection.collapsed(offset: draft.text.length);
    if (attachment == null && pending.message.attachment != null) {
      setAttachment(pending.message.attachment);
    }
    _textActionsOffered = _textActionsOffered || pending.offersActions;
    notifyListeners();
    return true;
  }

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
      attachment != null ||
      (_textActionsOffered && draft.text.trim().isNotEmpty);

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
    final pending = _pendingSubmission;
    onDraftChanged(
      pending == null
          ? draft.text
          : [
              pending.draft,
              draft.text,
            ].where((text) => text.isNotEmpty).join('\n\n'),
    );
    notifyListeners();
  }

  Future<void> addMessage(
    ChatMessage message, {
    int? submittedDraftRevision,
    int? submittedAttachmentRevision,
    String? title,
  }) async {
    final attachmentUnchanged =
        _attachmentRevision == submittedAttachmentRevision;
    if (message.role == ChatRole.user && _pendingSubmission != null) {
      final pending = _pendingSubmission!;
      _pendingSubmission = null;
      await controller.updateMessage(
        _viewMessage(pending.message),
        _viewMessage(message),
      );
    } else {
      await controller.insertMessage(_viewMessage(message));
    }
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
    } else if (submittedDraftRevision != null) {
      onDraftChanged(draft.text);
    }
    if (submittedAttachmentRevision != null && !attachmentUnchanged) {
      onAttachmentChanged?.call(attachment);
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
