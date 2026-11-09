import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_text_action.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_quick_actions.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

void main() {
  late InMemoryChatRepository repository;
  const pasted = 'Wklejona treść do przetworzenia.';

  setUp(() {
    repository = InMemoryChatRepository();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return {'text': pasted};
          if (call.method == 'Clipboard.hasStrings') return {'value': true};
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        chatRepository: repository,
        modelFilesRepository: InMemoryModelFilesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
  }

  Future<void> pasteFromKeyboard(WidgetTester tester) async {
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    Actions.invoke(
      editable.context,
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Normal typing does not show quick actions', (tester) async {
    await open(tester);
    for (var length = 1; length <= 'Zwykłe pytanie'.length; length++) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: 'Zwykłe pytanie'.substring(0, length),
          selection: TextSelection.collapsed(offset: length),
        ),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(ChatQuickActions), findsNothing);
  });

  testWidgets('Android keyboard clipboard insertion offers actions', (
    tester,
  ) async {
    expect(defaultTargetPlatform, TargetPlatform.android);
    await open(tester);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: pasted,
        selection: TextSelection.collapsed(offset: pasted.length),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatQuickActions), findsOneWidget);
    final conversation = (await repository.getConversations()).first;
    expect(await repository.getMessages(conversation.id), isEmpty);
  });

  testWidgets('IME composing text does not offer quick actions', (
    tester,
  ) async {
    expect(defaultTargetPlatform, TargetPlatform.android);
    await open(tester);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'pisanie',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 0, end: 7),
      ),
    );
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'pisanie',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatQuickActions), findsNothing);
  });

  testWidgets('Keyboard paste offers all actions without sending', (
    tester,
  ) async {
    await open(tester);
    await pasteFromKeyboard(tester);
    expect(find.byType(ChatQuickActions), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(3));
    final conversations = await repository.getConversations();
    expect(await repository.getMessages(conversations.first.id), isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      pasted,
    );
  });

  testWidgets('The native paste menu also offers quick actions', (
    tester,
  ) async {
    await open(tester);
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    await editable.clipboardStatus.update();
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    final toolbar = field.contextMenuBuilder!(
      tester.element(find.byType(TextField)),
      editable,
    ) as AdaptiveTextSelectionToolbar;
    final paste = toolbar.buttonItems!.singleWhere(
      (item) => item.kind == ContextMenuButtonKind.paste,
    );
    paste.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(ChatQuickActions), findsOneWidget);
  });

  testWidgets(
    'Selecting summarize sends the pasted text with its instruction',
    (tester) async {
      await open(tester);
      await pasteFromKeyboard(tester);
      await tester.tap(find.text('Streść'));
      await tester.pumpAndSettle();
      final conversations = await repository.getConversations();
      final messages = await repository.getMessages(conversations.first.id);
      expect(messages.single.text, ChatTextAction.summarize.prompt(pasted));
      expect(find.byType(ChatQuickActions), findsNothing);
    },
  );
}
