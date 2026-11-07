import 'package:flutter_test/flutter_test.dart';

import 'support/test_application.dart';

void main() {
  androidScenario('Model download, verification and deletion ($e2ePhase)', (
    tester,
    app,
  ) async {
    switch (e2ePhase) {
      case 'download':
        await app.downloadModel(tester, requireTransfer: true);
      case 'delete':
        await app.verifyModel();
        await app.deleteModel(tester);
      default:
        throw StateError(
          'Model lifecycle requires E2E_PHASE=download or delete.',
        );
    }
    expect(tester.takeException(), isNull);
  });
}
