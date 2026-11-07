import 'support/pending_scenario.dart';

void main() {
  registerPendingAndroidScenario(
    'Loads a downloaded model on CPU and streams a non-empty response',
    timeout: const Duration(minutes: 10),
  );
}
