import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

enum ModelProbeStage { loading, generating, releasing }

abstract interface class ModelProbeRepository {
  Future<String> run(ModelFile model, void Function(ModelProbeStage) onStage);
}
