import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/llm_runtime_info.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/llm_repository.dart';

import 'support/in_memory_chat_repository.dart';
import 'support/in_memory_model_files_repository.dart';

class _Llm implements LlmRepository {
  final requests = <LlmComputeMode?>[];

  @override
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
    LlmComputeMode? computeMode,
    void Function(LlmRuntimeInfo)? onLoaded,
  }) async* {
    requests.add(computeMode);
    onLoaded?.call(
      const LlmRuntimeInfo(
        mode: LlmComputeMode.cpu,
        backend: 'CPU',
        gpuLayers: 0,
      ),
    );
    onStage(LlmStage.generating);
    yield 'Odpowiedź';
  }

  @override
  void stop() {}
  @override
  Future<void> unload() async {}
}

void main() {
  testWidgets('Home opens a CPU chat without an acceleration toggle', (
    tester,
  ) async {
    final llm = _Llm();
    await tester.pumpWidget(
      MyApp(
        chatRepository: InMemoryChatRepository(),
        modelFilesRepository: InMemoryModelFilesRepository(),
        llmRepository: llm,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Akceleracja GPU'), findsNothing);
    await tester.tap(find.text('Otwórz czat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pytanie');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(llm.requests, [LlmComputeMode.cpu]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
