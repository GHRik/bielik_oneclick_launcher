import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';

import 'package:characters/characters.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/chat_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

class UserMessageSaveFailure implements Exception {
  const UserMessageSaveFailure(this.cause);
  final Object cause;
}

class EmptyModelReply implements Exception {}

class ChatService {
  ChatService(this._repository, {LlmRepository? llmRepository})
    : _llm = llmRepository;

  final ChatRepository _repository;
  final LlmRepository? _llm;
  Future<void> _writes = Future.value();
  bool _active = false;
  bool _stopped = false;

  bool get hasLlm => _llm != null;

  Future<T> _write<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> saveDraft(int conversationId, String draft) =>
      _write(() => _repository.saveDraft(conversationId, draft));

  Future<void> saveDraftAttachment(
    int conversationId,
    TextAttachment? attachment,
  ) =>
      _write(() => _repository.saveDraftAttachment(conversationId, attachment));

  Future<void> send({
    required int conversationId,
    required String text,
    required List<ChatMessage> history,
    required FutureOr<void> Function(ChatUpdate) onUpdate,
    ModelFile? model,
    TextAttachment? attachment,
    void Function(LlmStage)? onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
  }) async {
    if (_active) throw StateError('A chat operation is already active.');
    if (history.any((message) => message.conversationId != conversationId)) {
      throw ArgumentError('History must belong to the active conversation.');
    }
    final message = text.trim();
    if (message.isEmpty && attachment == null) return;
    _active = true;
    _stopped = false;
    try {
      final title = history.isEmpty
          ? (message.isEmpty ? attachment!.name : message)
                .replaceAll(RegExp(r'\s+'), ' ')
                .characters
                .take(40)
                .toString()
          : null;
      var committed = false;
      Future<void> commitMessage() async {
        if (_stopped || committed) return;
        late ChatMessage saved;
        try {
          saved = await _write(
            () => _repository.addMessage(
              conversationId: conversationId,
              authorId: ChatAuthors.user,
              text: message,
              attachment: attachment,
              conversationTitle: title,
              clearDraft: true,
            ),
          );
        } catch (error) {
          throw UserMessageSaveFailure(error);
        }
        committed = true;
        await onUpdate(ChatMessageSaved(saved, title: title));
      }

      if (_llm == null) {
        await commitMessage();
        return;
      }
      if (model == null) throw StateError('No model selected.');
      final pending = ChatMessage(
        id: 'pending',
        conversationId: conversationId,
        authorId: ChatAuthors.user,
        text: message,
        attachment: attachment,
        createdAt: DateTime.now(),
      );
      await _reply(
        conversationId,
        model,
        [...history, pending],
        onUpdate,
        onStage ?? (_) {},
        computeMode,
        onLoaded,
        onContext,
        commitMessage,
      );
    } finally {
      _active = false;
    }
  }

  Future<void> _reply(
    int conversationId,
    ModelFile model,
    List<ChatMessage> history,
    FutureOr<void> Function(ChatUpdate) onUpdate,
    void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
    Future<void> Function() onPromptAccepted,
  ) async {
    final buffer = StringBuffer();
    String? responseId;
    final checkpoint = Stopwatch()..start();
    try {
      await for (final fragment in _llm!.generate(
        model,
        history,
        onStage: onStage,
        computeMode: computeMode,
        onLoaded: onLoaded,
        onContext: onContext,
        onPromptAccepted: onPromptAccepted,
      )) {
        if (_stopped) break;
        if (fragment.isEmpty) continue;
        if (responseId == null) onStage(LlmStage.generating);
        buffer.write(fragment);
        if (responseId == null) {
          final saved = await _write(
            () => _repository.addMessage(
              conversationId: conversationId,
              authorId: ChatAuthors.assistant,
              text: buffer.toString(),
              clearDraft: false,
            ),
          );
          responseId = saved.id;
          await onUpdate(ChatMessageSaved(saved));
        } else {
          await onUpdate(ChatMessageUpdated(responseId, buffer.toString()));
          if (checkpoint.elapsedMilliseconds >= 500) {
            await _write(
              () => _repository.updateMessage(responseId!, buffer.toString()),
            );
            checkpoint.reset();
          }
        }
      }
      if (responseId == null && !_stopped) throw EmptyModelReply();
    } finally {
      _llm!.stop();
      if (responseId != null) {
        await _write(
          () => _repository.updateMessage(responseId!, buffer.toString()),
        );
      }
    }
  }

  void stop() {
    _stopped = true;
    _llm?.stop();
  }

  Future<void> unload() async {
    if (_active) throw StateError('Stop the chat operation before unloading.');
    await _llm?.unload();
  }

  Future<void> flush() async {
    while (true) {
      final writes = _writes;
      await writes;
      if (identical(writes, _writes)) return;
    }
  }
}
