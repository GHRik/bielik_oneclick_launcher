import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/model_probe_repository.dart';

class ModelProbePage extends StatefulWidget {
  const ModelProbePage({super.key, required this.model, required this.repository});

  final ModelFile model;
  final ModelProbeRepository repository;

  @override
  State<ModelProbePage> createState() => _ModelProbePageState();
}

class _ModelProbePageState extends State<ModelProbePage> {
  bool _running = false;
  String? _answer;
  String? _error;
  ModelProbeStage _stage = ModelProbeStage.loading;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _answer = null;
      _error = null;
    });
    try {
      final answer = await widget.repository.run(widget.model, (stage) {
        if (mounted) setState(() => _stage = stage);
      });
      if (mounted) setState(() => _answer = answer);
    } catch (error) {
      if (mounted) setState(() => _error = 'Próba nie powiodła się: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_running,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Próba Bielika 1.5B'),
          automaticallyImplyLeading: !_running,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Odpowiedz jednym krótkim zdaniem po polsku: czym jest sztuczna inteligencja?'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _running ? null : _run,
                child: const Text('Wygeneruj odpowiedź'),
              ),
              if (_running) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(switch (_stage) {
                  ModelProbeStage.loading => 'Ładowanie modelu…',
                  ModelProbeStage.generating => 'Generowanie odpowiedzi…',
                  ModelProbeStage.releasing => 'Zwalnianie modelu…',
                }),
              ],
              if (_answer != null) ...[
                const SizedBox(height: 24),
                SelectableText(_answer!),
              ],
              if (_error != null) ...[
                const SizedBox(height: 24),
                SelectableText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
