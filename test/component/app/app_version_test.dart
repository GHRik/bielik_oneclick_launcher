import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/app_version.dart';

import '../../support/in_memory_chat_repository.dart';
import '../../support/in_memory_model_files_repository.dart';

void main() {
  testWidgets('Installed version appears below settings on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MyApp(
        appVersion: const AppVersion(name: '1.0.9', build: 123),
        chatRepository: InMemoryChatRepository(),
        modelFilesRepository: InMemoryModelFilesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wersja 1.0.9'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Wersja 1.0.9')).dy,
      greaterThan(tester.getTopLeft(find.byIcon(Icons.settings_outlined)).dy),
    );
    expect(find.text('Otwórz czat').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
