import 'support/pending_scenario.dart';

void main() {
  registerPendingAndroidScenario(
    'Creates a conversation, restores it after restart and confirms deletion',
    timeout: const Duration(minutes: 3),
  );
}
