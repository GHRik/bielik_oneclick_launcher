import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/context_usage.dart';
import 'package:bielik_oneclick_launcher/src/presentation/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/src/presentation/pages/chat_page.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/chat/context_usage_indicator.dart';

import '../../support/in_memory_chat_repository.dart';

void main() {
  testWidgets('Unknown usage is not presented as zero percent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContextUsageIndicator())),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets(
    'Displays measured tokens and explains the context after tapping',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContextUsageIndicator(
              usage: ContextUsage(
                promptTokens: 400,
                responseTokens: 100,
                contextSize: 1000,
              ),
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      await tester.tap(find.byType(ContextUsageIndicator));
      await tester.pumpAndSettle();
      expect(find.text('Kontekst tej rozmowy'), findsOneWidget);
      expect(find.textContaining('500 / 1000'), findsOneWidget);
    },
  );

  testWidgets('Opening omission details acknowledges and hides the warning', (
    tester,
  ) async {
    var unread = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ContextUsageIndicator(
              usage: const ContextUsage(
                promptTokens: 42,
                contextSize: 100,
                omittedMessageIds: ['user', 'assistant'],
                omittedAttachmentNames: ['facts.txt'],
              ),
              showOmissionWarning: unread,
              onOmissionsAcknowledged: () => setState(() => unread = false),
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('context-omission-warning')),
      findsOneWidget,
    );
    await tester.tap(find.byType(ContextUsageIndicator));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('context-omission-warning')),
      findsNothing,
    );
    expect(find.textContaining('Pominięte wiadomości: 2'), findsOneWidget);
    expect(find.textContaining('facts.txt'), findsOneWidget);
    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('context-omission-warning')),
      findsNothing,
    );
  });

  testWidgets('Omission pulse finishes while the unread badge remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContextUsageIndicator(
            usage: ContextUsage(
              promptTokens: 42,
              contextSize: 100,
              omittedMessageIds: ['old'],
            ),
            showOmissionWarning: true,
          ),
        ),
      ),
    );
    final transform = find.descendant(
      of: find.byType(ContextUsageIndicator),
      matching: find.byType(Transform),
    );
    await tester.pump(const Duration(milliseconds: 225));
    expect(
      tester.widget<Transform>(transform).transform.entry(0, 0),
      greaterThan(1),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Transform>(transform).transform.entry(0, 0),
      closeTo(1, 0.0001),
    );
    expect(
      find.byKey(const ValueKey('context-omission-warning')),
      findsOneWidget,
    );
  });

  testWidgets('Reduced motion keeps the badge without a pulse', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ContextUsageIndicator(
              usage: ContextUsage(
                promptTokens: 42,
                contextSize: 100,
                omittedMessageIds: ['old'],
              ),
              showOmissionWarning: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 225));
    final transform = find.descendant(
      of: find.byType(ContextUsageIndicator),
      matching: find.byType(Transform),
    );
    expect(
      tester.widget<Transform>(transform).transform.entry(0, 0),
      closeTo(1, 0.0001),
    );
    expect(
      find.byKey(const ValueKey('context-omission-warning')),
      findsOneWidget,
    );
  });

  for (final width in [320.0, 390.0, 840.0]) {
    testWidgets('The chat toolbar fits at width $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workspace = ChatWorkspace(InMemoryChatRepository())
        ..useModel(bielikModels.last);
      await workspace.initialize();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: ChatPage(workspace: workspace, statisticSeries: const []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ContextUsageIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      final contextPosition = tester.getCenter(
        find.byType(ContextUsageIndicator),
      );
      final statsPosition = tester.getCenter(find.byTooltip('Statystyki'));
      expect(contextPosition.dx, lessThan(statsPosition.dx));
      await tester.pumpWidget(const SizedBox.shrink());
      workspace.dispose();
      await tester.pump();
    });
  }
}
