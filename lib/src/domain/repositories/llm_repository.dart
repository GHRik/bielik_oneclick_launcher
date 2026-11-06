import 'package:bielik_oneclick_launcher/src/domain/models/chat_message.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

enum LlmStage { loading, generating }

abstract interface class LlmRepository {
  Stream<String> generate(
    ModelFile model,
    List<ChatMessage> history, {
    required void Function(LlmStage) onStage,
  });
  void stop();
  Future<void> unload();
}
