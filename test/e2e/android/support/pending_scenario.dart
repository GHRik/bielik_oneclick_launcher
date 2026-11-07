import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void registerPendingAndroidScenario(
  String description, {
  required Duration timeout,
}) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    description,
    (_) async {
      throw UnimplementedError(
        'Implement the Android E2E scenario before removing skip.',
      );
    },
    skip: true,
    timeout: Timeout(timeout),
  );
}
