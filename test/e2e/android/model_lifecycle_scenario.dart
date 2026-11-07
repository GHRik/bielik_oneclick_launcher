import 'support/pending_scenario.dart';

void main() {
  registerPendingAndroidScenario(
    'Downloads a model, verifies readiness and deletes the local model',
    timeout: const Duration(minutes: 30),
  );
}
