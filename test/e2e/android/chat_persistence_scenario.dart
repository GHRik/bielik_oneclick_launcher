import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'support/test_application.dart';

void main() {
  androidScenario(
    'Persists a conversation across an Android process restart ($e2ePhase)',
    (tester, app) async {
      final support = await getApplicationSupportDirectory();
      final stateFile = File('${support.path}/e2e-chat-$e2eRunId.json');
      switch (e2ePhase) {
        case 'create':
          await app.downloadModel(tester);
          final workspace = await openChat(tester);
          await newChat(tester);
          final reply = await sendAndGenerate(
            tester,
            workspace,
            conversationPrompt,
          );
          const draft = 'Szkic zapisany przed restartem';
          await tester.enterText(find.byType(TextField), draft);
          await tester.pump();
          await workspace.flush();
          final persisted = (await app.chats.getConversations()).singleWhere(
            (c) => c.id == workspace.selected.id,
          );
          expect(persisted.draft, draft);
          await stateFile.writeAsString(
            jsonEncode({
              'id': workspace.selected.id,
              'prompt': conversationPrompt,
              'reply': reply,
              'draft': draft,
              'pid': pid,
            }),
            flush: true,
          );
        case 'verify':
          expect(
            await stateFile.exists(),
            isTrue,
            reason: 'The create phase must run first.',
          );
          final state = jsonDecode(
            await stateFile.readAsString(),
          ) as Map<String, dynamic>;
          expect(
            pid,
            isNot(state['pid']),
            reason: 'Verification must run in a new Android process.',
          );
          final workspace = await openChat(tester);
          await openSidebar(tester);
          final tile = find.widgetWithText(ListTile, state['prompt'] as String);
          await waitFor(
            tester,
            () => tile.evaluate().isNotEmpty,
            description: 'persisted conversation in the sidebar',
          );
          await tester.tap(tile);
          await waitFor(
            tester,
            () =>
                workspace.selected.id == state['id'] &&
                find.byType(TextField).hitTestable().evaluate().isNotEmpty,
            description: 'selected restored conversation',
          );

          expect(workspace.selected.messages.map((m) => m.text), [
            state['prompt'],
            state['reply'],
          ]);
          expect(workspace.selected.draft.text, state['draft']);
          expectRenderedReply(state['reply'] as String);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            state['draft'],
          );

          await deleteConversation(tester, app, workspace);
          await stateFile.delete();
        default:
          throw StateError(
            'Chat persistence requires E2E_PHASE=create or verify.',
          );
      }
    },
  );
}
