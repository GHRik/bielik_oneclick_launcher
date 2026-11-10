import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/app_exit_report.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_exit_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/app_exit_notice.dart';

class _Repository implements AppExitRepository {
  AppExitReport? report;
  final acknowledged = <String>[];
  bool fail = false;

  @override
  Future<AppExitReport?> readPreviousExit() async {
    if (fail) throw StateError('Unavailable');
    return report;
  }

  @override
  Future<void> acknowledge(AppExitReport value) async {
    acknowledged.add(value.id);
    report = null;
  }
}

Future<void> _open(WidgetTester tester, AppExitRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AppExitNotice(
        repository: repository,
        child: const Scaffold(body: Text('Application')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Confirmed low-memory exit explains how to reduce model memory', (
    tester,
  ) async {
    final repository = _Repository()
      ..report = const AppExitReport(
        id: '1',
        lowMemory: true,
        code: 'ANDROID_EXIT_3_STATUS_0',
      );
    await _open(tester, repository);
    expect(find.textContaining('braku pamięci RAM'), findsOneWidget);
    expect(find.textContaining('zmniejsz kontekst'), findsOneWidget);
    expect(repository.acknowledged, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(repository.acknowledged, ['1']);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, repository);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'Other exits show the diagnostic code without claiming low memory',
    (tester) async {
      final repository = _Repository()
        ..report = const AppExitReport(
          id: '2',
          lowMemory: false,
          code: 'ANDROID_EXIT_5_STATUS_11',
        );
      await _open(tester, repository);
      expect(find.textContaining('ANDROID_EXIT_5_STATUS_11'), findsOneWidget);
      expect(find.textContaining('z powodu braku pamięci RAM'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Diagnostic failures do not interrupt startup', (tester) async {
    await _open(tester, _Repository()..fail = true);
    expect(find.text('Application'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unavailable platforms start without an exit notice', (
    tester,
  ) async {
    await _open(tester, const UnavailableAppExitRepository());
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Exit notice requires explicit acknowledgement with OK', (
    tester,
  ) async {
    final repository = _Repository()
      ..report = const AppExitReport(
        id: '3',
        lowMemory: false,
        code: 'ANDROID_EXIT_0_STATUS_0',
      );
    await _open(tester, repository);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repository.acknowledged, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(repository.acknowledged, ['3']);
  });
}
