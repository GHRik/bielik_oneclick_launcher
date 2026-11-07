import 'package:flutter_test/flutter_test.dart';

import 'support/test_application.dart';

void main() {
  androidScenario('Generates a streamed reply using the real CPU backend', (
    tester,
    app,
  ) async {
    await app.downloadModel(tester);
    final workspace = await openChat(tester);
    await newChat(tester);

    final reply = await sendAndGenerate(
      tester,
      workspace,
      'Odpowiedz jednym słowem: jak nazywa się stolica Polski?',
    );

    expect(reply.trim(), isNotEmpty);
    final stored = await app.chats.getMessages(workspace.selected.id);
    expect(stored.last.text, reply);
    await deleteConversation(tester, app, workspace);
  });
}
