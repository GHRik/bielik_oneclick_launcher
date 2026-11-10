import 'dart:async';

import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/text_attachment.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';

import '../../support/in_memory_chat_repository.dart';

class _Resources implements DeviceResourcesRepository {
  _Resources(this.availableBytes);
  final int? availableBytes;
  int reads = 0;

  @override
  Future<DeviceResources> read() async {
    reads++;
    return DeviceResources(availableRamBytes: availableBytes);
  }
}

class _Llm implements LlmRepository {
  LlmStage initialStage = LlmStage.analyzing;
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
    Future<void> Function()? onPromptAccepted,
  }) async* {
    onStage(initialStage);
    await onPromptAccepted?.call();
    inputs.add(history);
    contextCallbacks.add(onContext);
    final stream = StreamController<String>();
    streams.add(stream);
    yield* stream.stream;
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
      scenario, {
      DeviceResourcesRepository? resources,
    }) async {
      await tester.runAsync(() async {
        final repository = InMemoryChatRepository();
        final llm = _Llm();
        final workspace = ChatWorkspace(
          repository,
          llmRepository: llm,
          deviceResourcesRepository: resources,
        )..useModel(bielikModels.first);
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

    for (final available in <int?>[1000000000, 8000000000, null]) {
      testWidgets(
        'RAM warning during loading with $available available bytes',
        (tester) async {
          final resources = _Resources(available);
          await withWorkspace(tester, (repository, llm, workspace) async {
            expect(workspace.showMemoryWarning, isFalse);
            llm.initialStage = LlmStage.loading;
            final send = workspace.sendMessage('Question');
            await _until(() => llm.streams.isNotEmpty && resources.reads > 0);

            expect(
              workspace.showMemoryWarning,
              available != null && available < 4000000000,
            );
            llm.streams.last.add('Reply');
            await llm.streams.last.close();
            await send;
            expect(workspace.showMemoryWarning, isFalse);
            expect(workspace.error, isNull);
          }, resources: resources);
        },
      );
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

    testWidgets('Shows analysis until the first nonempty response fragment', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        expect(workspace.generationStatus, 'Bielik myśli…');
        llm.streams.last.add('');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(workspace.generationStatus, 'Bielik myśli…');
        llm.streams.last.add('Reply');
        await _until(() => workspace.selected.messages.length == 2);
        expect(workspace.generationStatus, 'Bielik pisze…');
        await llm.streams.last.close();
        await send;
      });
    });

    testWidgets('Keeps the document and answer in a follow-up question', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        workspace.selected.setAttachment(
          const TextAttachment(
            name: 'facts.txt',
            text: 'The project name is Eagle.',
            sizeBytes: 26,
          ),
        );
        final first = workspace.sendMessage('Remember this document');
        await _until(() => llm.streams.isNotEmpty);
        llm.streams.last.add('The project is Eagle.');
        await llm.streams.last.close();
        await first;
        final second = workspace.sendMessage('What is the project name?');
        await _until(() => llm.streams.length == 2);
        expect(
          llm.inputs.last.first.promptText,
          contains('The project name is Eagle.'),
        );
        expect(llm.inputs.last[1].text, 'The project is Eagle.');
        expect(llm.inputs.last.last.text, 'What is the project name?');
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

    testWidgets(
      'Acknowledging omissions hides the warning until new messages are omitted',
      (tester) async {
        await withWorkspace(tester, (repository, llm, workspace) async {
          final send = workspace.sendMessage('Question');
          await _until(() => llm.streams.isNotEmpty);
          final report = llm.contextCallbacks.last!;
          const usage = ContextUsage(
            promptTokens: 42,
            contextSize: 100,
            omittedMessageIds: ['old-user', 'old-answer'],
          );
          report(usage);
          expect(workspace.hasUnseenContextOmissions, isTrue);
          workspace.acknowledgeContextOmissions();
          expect(workspace.hasUnseenContextOmissions, isFalse);
          report(usage);
          expect(workspace.hasUnseenContextOmissions, isFalse);
          report(
            const ContextUsage(
              promptTokens: 40,
              contextSize: 100,
              omittedMessageIds: ['old-user', 'old-answer', 'next-user'],
            ),
          );
          expect(workspace.hasUnseenContextOmissions, isTrue);
          await llm.streams.last.close();
          await send;
        });
      },
    );

    testWidgets('Context acknowledgements belong to their conversation', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final original = workspace.selected;
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        llm.contextCallbacks.last!(
          const ContextUsage(
            promptTokens: 42,
            contextSize: 100,
            omittedMessageIds: ['old'],
          ),
        );
        await workspace.newChat();
        workspace.acknowledgeContextOmissions();
        expect(workspace.hasUnseenContextOmissions, isFalse);
        workspace.selectConversation(original);
        expect(workspace.hasUnseenContextOmissions, isTrue);
        workspace.acknowledgeContextOmissions();
        await workspace.newChat();
        workspace.selectConversation(original);
        expect(workspace.hasUnseenContextOmissions, isFalse);
        await llm.streams.last.close();
        await send;
      });
    });

    testWidgets('A lower percentage alone does not signal omitted history', (
      tester,
    ) async {
      await withWorkspace(tester, (repository, llm, workspace) async {
        final send = workspace.sendMessage('Question');
        await _until(() => llm.streams.isNotEmpty);
        llm.contextCallbacks.last!(
          const ContextUsage(promptTokens: 80, contextSize: 100),
        );
        llm.contextCallbacks.last!(
          const ContextUsage(promptTokens: 42, contextSize: 100),
        );
        expect(workspace.hasUnseenContextOmissions, isFalse);
        await llm.streams.last.close();
        await send;
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
      'A storage failure preserves the draft without starting response generation',
      (tester) async {
        await withWorkspace(tester, (repository, llm, workspace) async {
          repository.failSend = true;
          workspace.selected.draft.text = 'Keep this';

          await workspace.sendMessage('Keep this');

          expect(workspace.selected.draft.text, 'Keep this');
          expect(workspace.error, contains('Nie udało się zapisać wiadomości'));
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
