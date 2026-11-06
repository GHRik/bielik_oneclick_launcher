import 'package:material_ui/material_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

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

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bielik')),
      body: Center(
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
