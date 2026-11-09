import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/system_clipboard_repository.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

void main() {
  late InMemoryChatRepository chats;
  String? copied;
  bool fail = false;
  const question = 'Moje całe pytanie 🙂\n\nDrugi akapit z **tekstem**.';

  setUp(() {
    chats = InMemoryChatRepository();
    copied = null;
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'clipboard_unavailable');
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<Finder> openQuestion(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        chatRepository: chats,
        modelFilesRepository: InMemoryModelFilesRepository(),
        clipboardRepository: const SystemClipboardRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), question);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    final conversation = (await chats.getConversations()).first;
    final message = (await chats.getMessages(conversation.id)).single;
    return find.byKey(ValueKey('copy-message-${message.id}'));
  }

  testWidgets('Copies the complete question to the system clipboard', (
    tester,
  ) async {
    final button = await openQuestion(tester);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(copied, question);
    expect(find.text('Skopiowano do schowka.'), findsOneWidget);
  });

  testWidgets('Does not touch the clipboard before the copy button is tapped', (
    tester,
  ) async {
    await openQuestion(tester);
    expect(copied, isNull);
  });

  testWidgets('Shows a failure message when copying fails', (tester) async {
    final button = await openQuestion(tester);
    fail = true;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się skopiować wiadomości.'), findsOneWidget);
    expect(find.text('Skopiowano do schowka.'), findsNothing);
  });
}
