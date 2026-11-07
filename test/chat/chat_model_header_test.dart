import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/chat_model_header.dart';

void main() {
  for (final width in [320.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Chat header fits a ${width}px toolbar at ${scale}x text scale',
        (tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(Size(width, 800));
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                appBar: AppBar(
                  leadingWidth: 104,
                  leading: const Row(
                    children: [BackButton(), Icon(Icons.menu)],
                  ),
                  title: const ChatModelHeader(
                    status: 'CPU · niezaładowany',
                    modelName: 'Bielik 4.5B v3.0 Instruct · Q8',
                  ),
                  actions: const [Icon(Icons.bar_chart), SizedBox(width: 24)],
                ),
                body: const Text('Treść rozmowy'),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(ChatModelHeader)).height,
            lessThanOrEqualTo(48),
          );
          final toolbarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
          expect(
            tester.getTopLeft(find.text('Treść rozmowy')).dy,
            toolbarBottom,
          );
        },
      );
    }
  }
}
