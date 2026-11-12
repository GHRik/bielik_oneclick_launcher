import 'package:flutter/services.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/android_app_info.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/google_play_update_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/play_update_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/play_update_button.dart';

class _Play implements PlayUpdateRepository {
  PlayUpdateStatus status = PlayUpdateStatus.available;
  int updates = 0;
  @override
  Future<PlayUpdateStatus> check() async => status;
  @override
  Future<PlayUpdateResult> update() async {
    updates++;
    return PlayUpdateResult.cancelled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Play builds retain updates when installer metadata is unavailable', () {
    const version = AppVersion(name: '1.0.15', build: 123);
    expect(version.usesGooglePlayUpdates(apkUpdatesEnabled: false), isTrue);
    expect(version.usesGooglePlayUpdates(apkUpdatesEnabled: true), isFalse);
    const installedByPlay = AppVersion(
      name: '1.0.15',
      build: 123,
      installedFromGooglePlay: true,
    );
    expect(
      installedByPlay.usesGooglePlayUpdates(apkUpdatesEnabled: true),
      isTrue,
    );
    expect(
      installedByPlay.usesGooglePlayUpdates(apkUpdatesEnabled: false),
      isTrue,
    );
  });

  test(
    'Installer metadata selects Play only for a positive native result',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(AndroidAppInfo.channel, null),
      );
      messenger.setMockMethodCallHandler(
        AndroidAppInfo.channel,
        (_) async => {
          'name': '1.0.15',
          'build': 123,
          'installedFromGooglePlay': true,
        },
      );
      expect((await AndroidAppInfo.version())!.installedFromGooglePlay, isTrue);
      messenger.setMockMethodCallHandler(
        AndroidAppInfo.channel,
        (_) async => {'name': '1.0.15', 'build': 123},
      );
      expect(
        (await AndroidAppInfo.version())!.installedFromGooglePlay,
        isFalse,
      );
    },
  );

  test(
    'Play adapter refreshes update information and preserves cancellation',
    () async {
      const channel = MethodChannel('de.ffuf.in_app_update/methods');
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return {
            'updateAvailability': 2,
            'immediateAllowed': true,
            'flexibleAllowed': true,
            'availableVersionCode': 124,
            'installStatus': 0,
            'packageName': 'bielik.ai',
            'clientVersionStalenessDays': null,
            'updatePriority': 0,
          };
        }
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });
      final repository = GooglePlayUpdateRepository();
      expect(await repository.check(), PlayUpdateStatus.available);
      expect(await repository.update(), PlayUpdateResult.cancelled);
      expect(calls, [
        'checkForUpdate',
        'checkForUpdate',
        'performImmediateUpdate',
      ]);
    },
  );

  test('Play errors remain in the Play channel', () async {
    const channel = MethodChannel('de.ffuf.in_app_update/methods');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'ERROR_API_NOT_AVAILABLE');
    });
    await expectLater(
      GooglePlayUpdateRepository().check(),
      throwsA(isA<Exception>()),
    );
  });

  testWidgets('Current Play version shows an informational message', (
    tester,
  ) async {
    final repository = _Play()..status = PlayUpdateStatus.current;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlayUpdateButton(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktualizuj'));
    await tester.pumpAndSettle();
    expect(find.text('Masz aktualną wersję aplikacji.'), findsOneWidget);
    expect(repository.updates, 0);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Play update is manual and cancellation keeps the app usable', (
    tester,
  ) async {
    final repository = _Play();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlayUpdateButton(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.updates, 0);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Aktualizuj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Później'));
    await tester.pumpAndSettle();
    expect(repository.updates, 0);
    await tester.tap(find.text('Aktualizuj'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Aktualizuj').last);
    await tester.pumpAndSettle();
    expect(repository.updates, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Aktualizuj').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'Interrupted Play updates resume without a second consent dialog',
    (tester) async {
      final repository = _Play()..status = PlayUpdateStatus.interrupted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayUpdateButton(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.updates, 1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
