import 'dart:async';

import 'package:bielik_oneclick_launcher/src/app.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_update.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/app_update_repository.dart';
import 'package:bielik_oneclick_launcher/src/presentation/widgets/home/app_update_button.dart';

class _Updates implements AppUpdateRepository {
  AppUpdate? update;
  UpdateFailure? failure;
  int checks = 0;
  int downloads = 0;
  int installs = 0;
  bool permitted = true;
  Completer<String>? pending;
  @override
  Future<AppUpdate?> check(int installedBuild) async {
    checks++;
    if (failure != null) throw failure!;
    return update;
  }

  @override
  Future<String> download(
    AppUpdate update,
    void Function(double) progress,
  ) async {
    downloads++;
    progress(0.5);
    return pending == null ? '/cache/update.apk' : pending!.future;
  }

  @override
  Future<bool> install(String path) async {
    installs++;
    return permitted;
  }

  @override
  void cancel() {}
}

Future<void> _open(WidgetTester tester, _Updates updates) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppUpdateButton(
          repository: updates,
          version: const AppVersion(name: '1.0.0', build: 1),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Aktualizuj'));
  await tester.pumpAndSettle();
}

AppUpdate _release() => AppUpdate(
  version: '1.0.9',
  build: 2,
  url: Uri.parse(
    'https://github.com/GHRik/bielik_oneclick_launcher/releases/download/v1/bielik-arm64.apk',
  ),
  sha256: '0' * 64,
  bytes: 10,
);

void main() {
  testWidgets(
    'Update button is centered below the version without checking on startup',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final updates = _Updates();
      await tester.pumpWidget(
        MyApp(
          appVersion: const AppVersion(name: '1.0.9', build: 42),
          appUpdateRepository: updates,
          chatRepository: InMemoryChatRepository(),
          modelFilesRepository: InMemoryModelFilesRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final version = find.text('Wersja 1.0.9');
      final button = find.text('Aktualizuj');
      expect(
        tester.getCenter(button).dx,
        closeTo(tester.getCenter(version).dx, 1),
      );
      expect(
        tester.getTopLeft(button).dy,
        greaterThan(tester.getBottomLeft(version).dy),
      );
      expect(updates.checks, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('No update reports the current version without downloading', (
    tester,
  ) async {
    final updates = _Updates();
    await _open(tester, updates);
    expect(find.text('Masz najnowszą wersję aplikacji.'), findsOneWidget);
    expect(updates.downloads, 0);
  });

  testWidgets('Offline check shows the return-online message', (tester) async {
    await _open(
      tester,
      _Updates()
        ..failure = const UpdateFailure(
          'Wróć tutaj, gdy będziesz znowu online.',
        ),
    );
    expect(find.text('Wróć tutaj, gdy będziesz znowu online.'), findsOneWidget);
  });

  testWidgets('Available update requires consent before downloading', (
    tester,
  ) async {
    final updates = _Updates()..update = _release();
    await _open(tester, updates);
    expect(updates.downloads, 0);
    await tester.tap(find.text('Pobierz i zainstaluj'));
    await tester.pumpAndSettle();
    expect(updates.downloads, 1);
    expect(updates.installs, 1);
    expect(
      find.textContaining('Instalator Androida został otwarty'),
      findsOneWidget,
    );
  });

  testWidgets('Missing installation permission allows retry after returning', (
    tester,
  ) async {
    final updates = _Updates()
      ..update = _release()
      ..permitted = false;
    await _open(tester, updates);
    await tester.tap(find.text('Pobierz i zainstaluj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zezwól tej aplikacji'), findsOneWidget);
    updates.permitted = true;
    await tester.tap(find.text('Zainstaluj'));
    await tester.pumpAndSettle();
    expect(updates.downloads, 1);
    expect(updates.installs, 2);
  });

  testWidgets('Download progress is shown before installation', (tester) async {
    final pending = Completer<String>();
    final updates = _Updates()
      ..update = _release()
      ..pending = pending;
    await _open(tester, updates);
    await tester.tap(find.text('Pobierz i zainstaluj'));
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
    expect(updates.installs, 0);
    pending.complete('/cache/update.apk');
    await tester.pumpAndSettle();
  });
}
