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

  void _showPlannedAction(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action będzie dostępne wkrótce.')),
      );
  }

  @override
  void dispose() {
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
                              onChanged: (model) {
                                if (model != null) {
                                  setState(() => _selectedModel = model);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _showPlannedAction('Pobieranie modeli'),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Pobierz'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showPlannedAction('Usuwanie modeli'),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Usuń'),
                                  ),
                                ),
                              ],
                            ),
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
