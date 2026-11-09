import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import '../../support/in_memory_chat_repository.dart';

class _Llm implements LlmRepository {
  final inputs = <List<ChatMessage>>[];
  final streams = <StreamController<String>>[];
  final contextCallbacks = <void Function(ContextUsage)?>[];
  int stops = 0;
  int unloads = 0;

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
    void Function(ContextUsage)? onContext,
  }) {
    inputs.add(history);
    contextCallbacks.add(onContext);
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
  Future<void> unload() async {
    unloads++;
  }
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 200 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ready(), isTrue);
}

void main() {
  group('Chat generation lifecycle', () {
    Future<void> withWorkspace(
      WidgetTester tester,
      Future<void> Function(InMemoryChatRepository, _Llm, ChatWorkspace)
      scenario,
    ) async {
      await tester.runAsync(() async {
        final repository = InMemoryChatRepository();
        final llm = _Llm();
        final workspace = ChatWorkspace(repository, llmRepository: llm)
          ..useModel(bielikModels.first);
        await workspace.initialize();
        try {
          await scenario(repository, llm, workspace);
        } finally {
          await workspace.stopGeneration();
          workspace.dispose();
          await workspace.flush();
        }
      });
      await tester.pump();
    }

    testWidgets('Ignores a duplicate send while generation is active', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);

        await workspace.sendMessage('Duplicate');

        expect(llm.inputs, hasLength(1));
        await llm.streams.last.close();
        await send;
      });
    });

    testWidgets(
      'Streams into the originating chat after switching conversations',
      (tester) async {
        await withWorkspace(tester, (repository, llm, workspace) async {
          final original = workspace.selected;
          final send = workspace.sendMessage('Question');
          await _until(() => llm.streams.isNotEmpty);
          llm.streams.last.add('Hello');
          await _until(() => original.messages.length == 2);
          await workspace.newChat();

          llm.streams.last.add(' world!');
          await llm.streams.last.close();
          await send;
          await workspace.flush();

          expect(workspace.selected.messages, isEmpty);
          expect(original.messages.last.text, 'Hello world!');
          expect(
            (await repository.getMessages(original.id)).last.text,
            'Hello world!',
          );
        });
      },
    );

    testWidgets('Preserves a draft typed while a reply is streaming', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);

        workspace.selected.draft.text = 'Next question';
        llm.streams.last.add('Reply');
        await llm.streams.last.close();
        await send;
        await workspace.flush();

        expect(
          (await repository.getConversations()).single.draft,
          'Next question',
        );
      });
    });

    testWidgets('Passes previous turns to the next generation', (tester) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final first = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        llm.streams.last.add('Reply');
        await llm.streams.last.close();
        await first;

        final second = workspace.sendMessage('Next question');
        await _until(() => llm.streams.length == 2);

        expect(llm.inputs.last.map((m) => m.text), [
          'Question',
          'Reply',
          'Next question',
        ]);
        await llm.streams.last.close();
        await second;
      });
    });

    testWidgets('Deleting a chat excludes its history from the next request', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final deleted = workspace.selected;
        final first = workspace.sendMessage('Old private text');
        await _until(() => llm.streams.isNotEmpty);
        llm.streams.last.add('Old answer');
        await llm.streams.last.close();
        await first;
        await workspace.deleteConversation(deleted);
        final second = workspace.sendMessage('New question');
        await _until(() => llm.streams.length == 2);
        expect(llm.inputs.last.map((message) => message.text), [
          'New question',
        ]);
        expect(llm.inputs.last.single.conversationId, workspace.selected.id);
        await llm.streams.last.close();
        await second;
      });
    });

    testWidgets('Context measurements belong only to the originating chat', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final original = workspace.selected;
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        await workspace.newChat();
        llm.contextCallbacks.last?.call(
          const ContextUsage(promptTokens: 50, contextSize: 100),
        );
        expect(workspace.contextUsage, isNull);
        workspace.selectConversation(original);
        expect(workspace.contextUsage?.percent, 50);
        await llm.streams.last.close();
        await send;
        await workspace.deleteConversation(original);
        expect(workspace.contextUsage, isNull);
      });
    });

    testWidgets('Releasing the model unloads the engine', (tester) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        await workspace.releaseModel();

        expect(llm.unloads, 1);
      });
    });

    testWidgets('Stopping generation preserves the partial answer', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final id = workspace.selected.id;
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        llm.streams.last.add('Partial');
        await _until(() => workspace.selected.messages.length == 2);

        await workspace.stopGeneration();
        await send;

        expect(workspace.sending, isFalse);
        expect(workspace.error, isNull);
        expect((await repository.getMessages(id)).last.text, 'Partial');
      });
    });

    testWidgets('Deleting the active conversation stops generation', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final original = workspace.selected;
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);

        await workspace.deleteConversation(original);
        await send;

        expect(llm.stops, greaterThan(0));
        expect(await repository.getMessages(original.id), isEmpty);
        expect(workspace.selected.id, isNot(original.id));
      });
    });

    testWidgets(
      'A storage failure preserves the draft without invoking the engine',
      (tester) async {
        await withWorkspace(tester, (repository, llm, workspace) async {
          repository.failSend = true;
          workspace.selected.draft.text = 'Keep this';

          await workspace.sendMessage('Keep this');

          expect(workspace.selected.draft.text, 'Keep this');
          expect(llm.streams, isEmpty);
        });
      },
    );

    testWidgets(
      'An engine failure preserves the partial answer and reports an error',
      (tester) async {
        await withWorkspace(tester, (repository, llm, workspace) async {
          final id = workspace.selected.id;
          final send = workspace.sendMessage('Question');
          await _until(() => llm.streams.isNotEmpty);
          llm.streams.last.add('Partial');
          await _until(() => workspace.selected.messages.length == 2);

          llm.streams.last.addError(StateError('Engine failed'));
          await send;

          expect(workspace.error, contains('Engine failed'));
          expect((await repository.getMessages(id)).last.text, 'Partial');
          expect(workspace.sending, isFalse);
        });
      },
    );
  });
}
