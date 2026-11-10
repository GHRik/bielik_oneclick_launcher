import 'package:flutter_test/flutter_test.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_input_composer.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/speech_recognition_repository.dart';

import '../../support/fake_speech_recognition_repository.dart';
import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

void main() {
  late FakeSpeechRecognitionRepository speech;
  late InMemoryChatRepository chats;

  setUp(() {
    speech = FakeSpeechRecognitionRepository();
    chats = InMemoryChatRepository();
  });

  Future<void> open(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MyApp(
        chatRepository: chats,
        modelFilesRepository: InMemoryModelFilesRepository(),
        speechRepository: speech,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
  }

  String draft(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Dyktuj wiadomość'));
    await tester.pumpAndSettle();
  }

  testWidgets('Opening chat does not request microphone access', (
    tester,
  ) async {
    await open(tester);
    expect(speech.starts, 0);
    expect(find.byTooltip('Dyktuj wiadomość'), findsOneWidget);
  });

  testWidgets('The microphone is left of the send button', (tester) async {
    await open(tester);
    expect(
      tester.getCenter(find.byTooltip('Dyktuj wiadomość')).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.send)).dx),
    );
  });

  testWidgets('The microphone stays inside the painted composer area', (
    tester,
  ) async {
    await open(tester);
    final microphone = tester.getCenter(find.byTooltip('Dyktuj wiadomość'));
    expect(
      tester.getRect(find.byType(ChatInputComposer)).contains(microphone),
      isTrue,
    );
  });

  testWidgets('Speech updates the draft without sending it', (tester) async {
    await open(tester);
    await start(tester);
    speech.text!('Hej');
    speech.text!('Hej Bielik');
    await tester.pumpAndSettle();
    expect(draft(tester), 'Hej Bielik');
    expect(
      await chats.getMessages((await chats.getConversations()).first.id),
      isEmpty,
    );
  });

  testWidgets('Finishing dictation shows text actions without sending', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    speech.text!('Tekst do streszczenia');
    await tester.pumpAndSettle();
    expect(find.text('Streść'), findsNothing);
    speech.done!();
    await tester.pumpAndSettle();
    for (final label in ['Przetłumacz', 'Streść', 'Analizuj']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(draft(tester), 'Tekst do streszczenia');
    expect(
      await chats.getMessages((await chats.getConversations()).first.id),
      isEmpty,
    );
  });

  testWidgets(
    'Finishing without recognized speech does not offer actions for an existing draft',
    (tester) async {
      await open(tester);
      tester.widget<TextField>(find.byType(TextField)).controller!.text =
          'Wpisany tekst';
      await start(tester);
      speech.done!();
      await tester.pumpAndSettle();
      expect(find.text('Streść'), findsNothing);
      expect(draft(tester), 'Wpisany tekst');
    },
  );

  testWidgets('A second tap stops dictation before manual sending', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    speech.text!('Hello');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zatrzymaj dyktowanie'));
    await tester.pump();
    expect(speech.stops, 1);
    speech.text!('Hello Bielik');
    speech.done!();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(
      (await chats.getMessages((await chats.getConversations()).first.id))
          .single
          .text,
      'Hello Bielik',
    );
  });

  testWidgets('Permission denial leaves normal typing available', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    speech.failure!(SpeechFailure.permissionDenied);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Typed instead');
    expect(draft(tester), 'Typed instead');
    expect(find.textContaining('Brak dostępu do mikrofonu'), findsOneWidget);
  });

  testWidgets('Changing conversations ignores late speech results', (
    tester,
  ) async {
    await open(tester);
    await start(tester);
    speech.text!('Old draft');
    await tester.pumpAndSettle();
    final lateResult = speech.text!;
    await tester.tap(find.byTooltip('Rozmowy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Nowa rozmowa'));
    await tester.pumpAndSettle();
    lateResult('Wrong chat');
    await tester.pumpAndSettle();
    expect(draft(tester), isEmpty);
  });

  testWidgets('Leaving the chat cancels microphone use', (tester) async {
    await open(tester);
    await start(tester);
    final before = speech.cancellations;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(speech.cancellations, greaterThan(before));
  });

  testWidgets('Backgrounding the app cancels dictation', (tester) async {
    await open(tester);
    await start(tester);
    final before = speech.cancellations;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(speech.cancellations, greaterThan(before));
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  });

  testWidgets('The composer fits a narrow screen with a long draft', (
    tester,
  ) async {
    await open(tester, width: 320);
    await start(tester);
    speech.text!('Long dictated message ' * 20);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byTooltip('Zatrzymaj dyktowanie')).right,
      lessThanOrEqualTo(320),
    );
  });
}
