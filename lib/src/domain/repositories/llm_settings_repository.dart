import 'package:bielik_oneclick_launcher/src/domain/models/llm_configuration.dart';

abstract interface class LlmSettingsRepository {
  Future<LlmConfiguration?> load();
  Future<void> save(LlmConfiguration configuration);
}
