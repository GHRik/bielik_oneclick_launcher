import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

class _Llm implements LlmRepository {
  int unloads = 0;
  StreamController<String>? pending;

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
    await onPromptAccepted?.call();
    onLoaded?.call(
      const LlmRuntimeInfo(
        mode: LlmComputeMode.cpu,
        backend: 'cpu',
        gpuLayers: 0,
      ),
    );
    yield* pending?.stream ?? Stream.value('Reply');
  }

  @override
  void stop() {
    final stream = pending;
    if (stream != null && !stream.isClosed) unawaited(stream.close());
  }

  @override
  Future<void> unload() async {
    unloads++;
  }
}

void main() {
  late _Llm llm;

  Future<void> open(WidgetTester tester) async {
    llm = _Llm();
    await tester.pumpWidget(
      MyApp(
        chatRepository: InMemoryChatRepository(),
        modelFilesRepository: InMemoryModelFilesRepository(),
        llmRepository: llm,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Question');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    llm.unloads = 0;
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('Returning home keeps the model for two idle minutes', (
    tester,
  ) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(llm.unloads, 0);
    await tester.pump(const Duration(seconds: 119));
    expect(llm.unloads, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(llm.unloads, 1);
    await close(tester);
  });

  testWidgets('Reopening the same chat cancels idle unloading', (tester) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 3));
    expect(llm.unloads, 0);
    expect(find.text('CPU'), findsOneWidget);
    await close(tester);
  });

  testWidgets('Opening settings without saving retains the model', (
    tester,
  ) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    expect(llm.unloads, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(llm.unloads, 0);
    await close(tester);
  });

  testWidgets('Saving only the prompt retains the model and editor value', (
    tester,
  ) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('system-prompt'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Odpowiadaj zwięźle.');
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(llm.unloads, 0);
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Odpowiadaj zwięźle.',
    );
    await close(tester);
  });

  testWidgets('Changing model settings unloads the retained model', (
    tester,
  ) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Konfiguracja LLM'));
    await tester.pumpAndSettle();
    final contextField = find.widgetWithText(
      TextField,
      'Rozmiar kontekstu (tokeny)',
    );
    await tester.ensureVisible(contextField);
    await tester.enterText(contextField, '4096');
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(llm.unloads, 1);
    await close(tester);
  });

  testWidgets('Backgrounding an open chat does not unload the model', (
    tester,
  ) async {
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await Future<void>.value();
    expect(llm.unloads, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await close(tester);
  });

  testWidgets('The idle timeout does not interrupt an active answer', (
    tester,
  ) async {
    await open(tester);
    llm.pending = StreamController<String>();
    await tester.enterText(find.byType(TextField), 'Another question');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(minutes: 3));
    expect(llm.unloads, 0);
    llm.pending!.add('Complete');
    unawaited(llm.pending!.close());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 2));
    await tester.pump();
    expect(llm.unloads, 1);
    await close(tester);
  });
}
