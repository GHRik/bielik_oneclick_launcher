import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_model_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import 'support/in_memory_chat_repository.dart';

class _Llm implements LlmRepository {
  final inputs = <List<ChatMessage>>[];
  final streams = <StreamController<String>>[];
  int stops = 0;
  int unloads = 0;

  @override
  Stream<String> generate(ModelFile model, List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
  }) {
    inputs.add(history);
    final stream = StreamController<String>();
    streams.add(stream);
    onStage(LlmStage.generating);
    return stream.stream;
  }

  @override
  void stop() {
    stops++;
    if (streams.isNotEmpty && !streams.last.isClosed) {
      unawaited(streams.last.close());
    }
  }

  @override
  Future<void> unload() async { unloads++; }
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 200 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ready(), isTrue);
}

void main() {
  testWidgets('Streams to the originating chat, saves drafts and reuses history', (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository();
      final llm = _Llm();
      final workspace = ChatWorkspace(repository, llmRepository: llm)
        ..useModel(bielikModels.first);
      await workspace.initialize();
      final original = workspace.selected;
      original.draft.text = 'Pytanie';
      final send = workspace.sendMessage('Pytanie');
      await _until(() => llm.streams.isNotEmpty);
      await workspace.sendMessage('Duplikat');
      expect(llm.inputs, hasLength(1));
      llm.streams.last.add('Cześć');
      await _until(() => original.messages.length == 2);
      original.draft.text = 'Następne pytanie';
      await workspace.newChat();
      final other = workspace.selected;
      llm.streams.last.add(' świecie!');
      await llm.streams.last.close();
      await send;
      await workspace.flush();
      expect(other.messages, isEmpty);
      expect(original.messages.last.text, 'Cześć świecie!');
      expect((await repository.getMessages(original.id)).last.text, 'Cześć świecie!');
      expect((await repository.getConversations()).last.draft, 'Następne pytanie');
      workspace.selectConversation(original);
      final second = workspace.sendMessage('Następne pytanie');
      await _until(() => llm.streams.length == 2);
      expect(llm.inputs.last.map((m) => m.text), ['Pytanie', 'Cześć świecie!', 'Następne pytanie']);
      llm.streams.last.add('Druga odpowiedź');
      await llm.streams.last.close();
      await second;
      expect(workspace.error, isNull);
      await workspace.releaseModel();
      expect(llm.unloads, 1);
      workspace.dispose();
      await workspace.flush();
    });
  });

  testWidgets('Stopping preserves partial answer and deletion stops active generation', (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository();
      final llm = _Llm();
      final workspace = ChatWorkspace(repository, llmRepository: llm)
        ..useModel(bielikModels.first);
      await workspace.initialize();
      final original = workspace.selected;
      final send = workspace.sendMessage('Pytanie');
      await _until(() => llm.streams.isNotEmpty);
      llm.streams.last.add('Fragment');
      await _until(() => original.messages.length == 2);
      await workspace.stopGeneration();
      await send;
      expect(workspace.sending, isFalse);
      expect((await repository.getMessages(original.id)).last.text, 'Fragment');
      expect(workspace.error, isNull);
      final next = workspace.sendMessage('Kolejne');
      await _until(() => llm.streams.length == 2);
      await workspace.deleteConversation(original);
      await next;
      expect(await repository.getMessages(original.id), isEmpty);
      expect(workspace.selected.id, isNot(original.id));
      workspace.dispose();
      await workspace.flush();
    });
    await tester.pump();
  });

  testWidgets('Persistence failures retain draft; engine failures retain partial answer', (tester) async {
    await tester.runAsync(() async {
      final repository = InMemoryChatRepository()..failSend = true;
      final llm = _Llm();
      final workspace = ChatWorkspace(repository, llmRepository: llm)
        ..useModel(bielikModels.first);
      await workspace.initialize();
      workspace.selected.draft.text = 'Nie zgub';
      await workspace.sendMessage('Nie zgub');
      expect(workspace.selected.draft.text, 'Nie zgub');
      expect(llm.streams, isEmpty);
      repository.failSend = false;
      final send = workspace.sendMessage('Nie zgub');
      await _until(() => llm.streams.isNotEmpty);
      llm.streams.last.add('Częściowa');
      await _until(() => workspace.selected.messages.length == 2);
      llm.streams.last.addError(StateError('Błąd silnika'));
      await send;
      expect(workspace.error, contains('Błąd silnika'));
      expect((await repository.getMessages(workspace.selected.id)).last.text, 'Częściowa');
      expect(workspace.sending, isFalse);
      workspace.dispose();
      await workspace.flush();
    });
  });
}
