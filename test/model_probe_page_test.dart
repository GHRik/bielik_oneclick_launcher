import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/data/datasources/preview_model_datasource.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_probe_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/model_probe_page.dart';

class _Probe implements ModelProbeRepository {
  Completer<String> result = Completer<String>();
  int calls = 0;

  @override
  Future<String> run(ModelFile model, void Function(ModelProbeStage) onStage) {
    calls++;
    onStage(ModelProbeStage.generating);
    return result.future;
  }
}

void main() {
  testWidgets('Shows progress, prevents duplicate runs and displays the answer', (tester) async {
    final probe = _Probe();
    await tester.pumpWidget(MaterialApp(
      home: ModelProbePage(model: bielikModels.first.file!, repository: probe),
    ));
    await tester.tap(find.text('Wygeneruj odpowiedź'));
    await tester.pump();
    expect(find.text('Generowanie odpowiedzi…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(probe.calls, 1);
    probe.result.complete('AI to program uczący się na danych.');
    await tester.pumpAndSettle();
    expect(find.text('AI to program uczący się na danych.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reports failure and allows retry', (tester) async {
    final probe = _Probe();
    await tester.pumpWidget(MaterialApp(
      home: ModelProbePage(model: bielikModels.first.file!, repository: probe),
    ));
    await tester.tap(find.text('Wygeneruj odpowiedź'));
    await tester.pump();
    probe.result.completeError(StateError('Brak modelu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Brak modelu'), findsOneWidget);
    probe.result = Completer<String>();
    await tester.tap(find.text('Wygeneruj odpowiedź'));
    await tester.pump();
    probe.result.complete('Działa.');
    await tester.pumpAndSettle();
    expect(find.text('Działa.'), findsOneWidget);
    expect(probe.calls, 2);
  });
}
