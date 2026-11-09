import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/model_memory_warning_button.dart';

void main() {
  testWidgets('Tapping the red RAM warning opens an explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ModelMemoryWarningButton(modelName: 'Bielik 4.5B'),
          ),
        ),
      ),
    );

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded)).color,
      const Color(0xFFFF1744),
    );
    await tester.tap(find.byTooltip('Informacja o pamięci RAM'));
    await tester.pumpAndSettle();
    expect(find.textContaining('aplikacja może się zamknąć'), findsOneWidget);
    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
