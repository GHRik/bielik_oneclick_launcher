import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'bielik_models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bielik',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _chatController = InMemoryChatController();
  BielikModel _selectedModel = bielikModels.first;
  Timer? _downloadTimer;
  double _downloadedMb = 0;
  static const double _demoSpeedMb = 20;
  bool _showDownload = false;
  bool _downloadComplete = false;

  bool get _isDownloading => _downloadTimer?.isActive ?? false;

  double get _downloadProgress =>
      (_downloadedMb / _selectedModel.downloadSizeMb).clamp(0.0, 1.0);

  String get _remainingTime {
    final seconds =
        ((_selectedModel.downloadSizeMb - _downloadedMb) / _demoSpeedMb)
            .ceil();
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }

  void _startDownloadPreview() {
    setState(() {
      _downloadedMb = 0;
      _showDownload = true;
      _downloadComplete = false;
      _downloadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _downloadedMb = (_downloadedMb + _demoSpeedMb)
              .clamp(0.0, _selectedModel.downloadSizeMb);
          if (_downloadProgress >= 1) {
            timer.cancel();
            _downloadComplete = true;
          }
        });
      });
    });
  }

  void _cancelDownloadPreview() {
    setState(() {
      _downloadTimer?.cancel();
      _showDownload = false;
      _downloadedMb = 0;
    });
  }

  void _showPlannedAction(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action będzie dostępne wkrótce.')),
      );
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bielik')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48)
                          .clamp(0.0, double.infinity),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Wybierz model Bielika',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<BielikModel>(
                              initialValue: _selectedModel,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final model in bielikModels)
                                  DropdownMenuItem(
                                    value: model,
                                    child: Text(model.name),
                                  ),
                              ],
                              onChanged: _isDownloading ? null : (model) {
                                if (model != null) {
                                  setState(() {
                                    _selectedModel = model;
                                    _showDownload = false;
                                    _downloadComplete = false;
                                    _downloadedMb = 0;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isDownloading
                                        ? null
                                        : _startDownloadPreview,
                                    icon: const Icon(Icons.download),
                                    label: Text(
                                      _isDownloading
                                          ? '${(_downloadProgress * 100).floor()}%'
                                          : 'Pobierz',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isDownloading
                                        ? null
                                        : () => _showPlannedAction('Usuwanie modeli'),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Usuń'),
                                  ),
                                ),
                              ],
                            ),
                            if (_showDownload) ...[
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _downloadComplete
                                            ? 'Symulacja zakończona · 100%'
                                            : 'Symulacja pobierania · ${(_downloadProgress * 100).floor()}%',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                        value: _downloadProgress,
                                        semanticsLabel: 'Postęp symulacji pobierania',
                                        semanticsValue:
                                            '${(_downloadProgress * 100).floor()}%',
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            'Prędkość: ${_isDownloading ? _demoSpeedMb.toStringAsFixed(1) : '0,0'} MB/s',
                                          ),
                                          Text('Pozostało (ETA): $_remainingTime'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Podgląd interfejsu — bez pobierania plików.',
                                      ),
                                      if (_isDownloading)
                                        TextButton(
                                          onPressed: _cancelDownloadPreview,
                                          child: const Text('Anuluj pobieranie'),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wymagania modelu',
                                      style: Theme.of(context)
                                          .textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Miejsce na dysku: ${_selectedModel.diskSpace}',
                                        ),
                                        const Chip(
                                          avatar: Icon(Icons.storage, size: 18),
                                          label: Text('Wolne miejsce u Ciebie: — GB'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'RAM (szacunkowo): ${_selectedModel.ram}',
                                        ),
                                        const Chip(
                                          avatar: Icon(Icons.memory, size: 18),
                                          label: Text('RAM Twojego telefonu: — GB'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Zużycie RAM zależy od długości rozmowy i silnika AI.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatPage(chatController: _chatController),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Otwórz czat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatController});

  final InMemoryChatController chatController;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _userId = 'local-user';
  int _messageSequence = 0;

  void _sendMessage(String text) {
    final message = text.trim();
    if (message.isEmpty) return;

    widget.chatController.insertMessage(
      TextMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-${_messageSequence++}',
        authorId: _userId,
        createdAt: DateTime.now().toUtc(),
        text: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Czat')),
      body: Chat(
        chatController: widget.chatController,
        currentUserId: _userId,
        onMessageSend: _sendMessage,
        resolveUser: (id) async => User(id: id, name: 'Ty'),
        builders: Builders(
          composerBuilder: (context) => const Composer(
            hintText: 'Napisz wiadomość…',
            attachmentIcon: null,
            sendIcon: Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
          ),
        ),
      ),
    );
  }
}
