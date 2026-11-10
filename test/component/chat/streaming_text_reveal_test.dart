import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/math_markdown.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/streaming_text_reveal.dart';

Future<void> _show(
  WidgetTester tester,
  String text, {
  bool streaming = true,
  bool reducedMotion = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(
        body: StreamingTextReveal(
          revision: text,
          streaming: streaming,
          child: MarkdownBody(
            data: text,
            inlineSyntaxes: [MathInlineSyntax()],
            builders: {
              'math': MathElementBuilder(const TextStyle(fontSize: 14)),
              'math-block': MathElementBuilder(
                const TextStyle(fontSize: 14),
                block: true,
              ),
            },
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('Existing glyphs stay opaque while incoming glyphs fade in', (
    tester,
  ) async {
    final boundary = GlobalKey();
    Future<void> show(String text) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: Colors.black,
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: StreamingTextReveal(
                      revision: text,
                      streaming: true,
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontFamily: 'Ahem',
                          fontSize: 20,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<int> redAt(int x, int y) async {
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final value = bytes!.getUint8((y * image.width + x) * 4);
        image.dispose();
        return value;
      }))!;
    }

    await show('A');
    await tester.pumpAndSettle();
    await show('AB');
    await tester.pump(const Duration(milliseconds: 90));
    expect(await redAt(10, 10), 255);
    expect(await redAt(30, 10), inExclusiveRange(20, 230));
    await tester.pumpAndSettle();
    expect(await redAt(30, 10), 255);
  });

  testWidgets('Only streaming replies animate', (tester) async {
    await _show(tester, 'Zapisana odpowiedź', streaming: false);
    expect(tester.hasRunningAnimations, isFalse);
    await _show(tester, 'Nowa odpowiedź');
    await _show(tester, 'Nowa odpowiedź z dopiskiem');
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completing generation immediately exposes the final source', (
    tester,
  ) async {
    await _show(tester, 'Początek');
    await _show(tester, '**Cała odpowiedź**', streaming: false);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Cała odpowiedź', findRichText: true), findsOneWidget);
  });

  testWidgets('Reduced motion disables the streaming effect', (tester) async {
    await _show(tester, 'Tekst', reducedMotion: true);
    await _show(tester, 'Tekst z dopiskiem', reducedMotion: true);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New text can wrap without layout errors', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _show(tester, 'Początek zdania');
    await tester.pumpAndSettle();
    await _show(tester, 'Początek zdania ${'dalszy tekst ' * 20}');
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('Math and code retain their formatting during streaming', (
    tester,
  ) async {
    await _show(tester, r'Wzór: $F_n = F_{n-1}$');
    await tester.pumpAndSettle();
    await _show(
      tester,
      r'Wzór: $F_n = F_{n-1}$'
      '\n\n```dart\nprint(1);\n```',
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(Math), findsOneWidget);
    expect(
      find.textContaining('print(1);', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('Animation ticks do not rebuild message content', (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StreamingTextReveal(
          revision: 'A',
          streaming: true,
          child: Builder(
            builder: (_) {
              builds++;
              return const Text('A');
            },
          ),
        ),
      ),
    );
    final initialBuilds = builds;
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 30));
    expect(builds, initialBuilds);
    await tester.pumpAndSettle();
  });
}
