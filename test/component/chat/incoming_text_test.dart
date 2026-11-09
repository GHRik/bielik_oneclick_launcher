import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/incoming_text_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _IncomingText implements IncomingTextRepository {
  final controller = StreamController<String>();
  @override
  Stream<String> get incomingText => controller.stream;
}

class _UnloadedLlm extends Fake implements LlmRepository {
  @override
  void stop() {}

  @override
  Future<void> unload() async {}
}

void main() {
  group('Incoming text drafts', () {
    late InMemoryChatRepository repository;
    late ChatWorkspace workspace;
    setUp(() {
      repository = InMemoryChatRepository();
      workspace = ChatWorkspace(repository, llmRepository: _UnloadedLlm());
    });
    tearDown(() async {
      workspace.dispose();
      await workspace.flush();
    });

    test(
      'Creates a conversation when importing into an empty workspace',
      () async {
        await workspace.importText('Hej Bielik');
        expect(workspace.selected.draft.text, 'Hej Bielik');
      },
    );

    test('Imports into the first conversation in the list', () async {
      await workspace.initialize();
      await workspace.newChat();
      final first = workspace.conversations.first;
      await workspace.importText('Selected text');
      expect(workspace.selected, same(first));
    });

    test(
      'Appends imported text without overwriting the existing draft',
      () async {
        await workspace.initialize();
        workspace.selected.draft.text = 'Existing draft';
        await workspace.importText('Selected text');
        expect(
          workspace.selected.draft.text,
          'Existing draft\n\nSelected text',
        );
      },
    );

    test('Persists the imported draft', () async {
      await workspace.importText('Saved selection');
      expect(
        (await repository.getConversations()).first.draft,
        'Saved selection',
      );
    });

    test('Does not send a message or invoke inference', () async {
      await workspace.importText('Do not send me');
      expect(await repository.getMessages(workspace.selected.id), isEmpty);
      expect(workspace.sending, isFalse);
      expect(workspace.runtimeInfo, isNull);
    });

    test('Imports successfully after an earlier send failure', () async {
      await workspace.initialize();
      repository.failSend = true;
      await workspace.sendMessage('Unsent');
      repository.failSend = false;
      expect(await workspace.importText('Selection'), isTrue);
    });

    test('Rejects whitespace without creating a conversation', () async {
      expect(await workspace.importText('   '), isFalse);
      expect(await repository.getConversations(), isEmpty);
    });

    test('Rejects oversized text without changing a draft', () async {
      await workspace.initialize();
      workspace.selected.draft.text = 'Keep';
      await workspace.importText('x' * 65537);
      expect(workspace.selected.draft.text, 'Keep');
    });

    test(
      'Reports a database failure without importing into another chat',
      () async {
        repository.failRead = true;
        expect(await workspace.importText('Selection'), isFalse);
        expect(workspace.ready, isFalse);
      },
    );
  });

  group('Incoming text navigation', () {
    late _IncomingText incoming;
    late InMemoryChatRepository repository;
    setUp(() {
      incoming = _IncomingText();
      repository = InMemoryChatRepository();
    });
    tearDown(() => incoming.controller.close());

    Future<void> openApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          chatRepository: repository,
          modelFilesRepository: InMemoryModelFilesRepository(),
          incomingTextRepository: incoming,
          llmRepository: _UnloadedLlm(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Handles text queued before the app is initialized', (
      tester,
    ) async {
      incoming.controller.add('Cold start');
      await openApp(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Cold start',
      );
    });

    testWidgets('Opens the first chat with a draft when text arrives', (
      tester,
    ) async {
      await openApp(tester);
      incoming.controller.add('From another app');
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'From another app',
      );
    });

    testWidgets('Repeated imports reuse the existing chat route', (
      tester,
    ) async {
      await openApp(tester);
      incoming.controller.add('First');
      await tester.pumpAndSettle();
      incoming.controller.add('Second');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'First\n\nSecond',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsNothing);
    });
  });
}
