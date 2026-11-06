import 'package:material_ui/material_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class _Conversation {
  _Conversation(this.id);

  final int id;
  final controller = InMemoryChatController();
  final draft = TextEditingController();
  String title = 'Nowa rozmowa';
  bool hasMessages = false;

  void dispose() {
    controller.dispose();
    draft.dispose();
  }
}

class ChatWorkspace extends ChangeNotifier {
  ChatWorkspace() {
    newChat();
  }

  final List<_Conversation> _conversations = [];
  int _nextId = 0;
  int _messageSequence = 0;
  late _Conversation _selected;

  void newChat() {
    _selected = _Conversation(_nextId++);
    _conversations.insert(0, _selected);
    notifyListeners();
  }

  void _select(_Conversation conversation) {
    _selected = conversation;
    notifyListeners();
  }

  void _sendMessage(String text) {
    final message = text.trim();
    if (message.isEmpty) return;

    _selected.controller.insertMessage(
      TextMessage(
        id: 'message-${_messageSequence++}',
        authorId: 'local-user',
        createdAt: DateTime.now().toUtc(),
        text: message,
      ),
    );
    if (!_selected.hasMessages) {
      _selected.hasMessages = true;
      _selected.title = message.replaceAll(RegExp(r'\s+'), ' ')
          .characters.take(40).toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final conversation in _conversations) {
      conversation.dispose();
    }
    super.dispose();
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.workspace});

  final ChatWorkspace workspace;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _closeSidebar() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState!.closeDrawer();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _newChat() {
    _closeSidebar();
    widget.workspace.newChat();
  }

  Widget _sidebar(BuildContext context) {
    final workspace = widget.workspace;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'Bielik',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _newChat,
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Twoje rozmowy',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: workspace._conversations.length,
                itemBuilder: (context, index) {
                  final conversation = workspace._conversations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      key: ValueKey('conversation-${conversation.id}'),
                      selected: conversation == workspace._selected,
                      selectedTileColor: colors.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(Icons.chat_bubble_outline, size: 20),
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _closeSidebar();
                        workspace._select(conversation);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chat() {
    final conversation = widget.workspace._selected;
    return Chat(
      key: ValueKey('chat-${conversation.id}'),
      chatController: conversation.controller,
      currentUserId: 'local-user',
      onMessageSend: widget.workspace._sendMessage,
      resolveUser: (id) async => User(id: id, name: 'Ty'),
      builders: Builders(
        emptyChatListBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'W czym mogę pomóc?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        composerBuilder: (context) => Composer(
          key: ValueKey('composer-${conversation.id}'),
          textEditingController: conversation.draft,
          hintText: 'Napisz wiadomość…',
          attachmentIcon: null,
          sendIcon: const Icon(Icons.send, semanticLabel: 'Wyślij wiadomość'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.workspace,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 840;
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              leadingWidth: showSidebar ? null : 104,
              leading: showSidebar
                  ? const BackButton()
                  : Row(
                      children: [
                        const BackButton(),
                        IconButton(
                          tooltip: 'Rozmowy',
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        ),
                      ],
                    ),
              title: const Text('Czat'),
              actions: [
                IconButton(
                  tooltip: 'New chat',
                  onPressed: _newChat,
                  icon: const Icon(Icons.edit_square),
                ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: showSidebar
                ? null
                : Drawer(width: 280, child: _sidebar(context)),
            body: Row(
              children: [
                if (showSidebar) ...[
                  SizedBox(width: 280, child: _sidebar(context)),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: _chat()),
              ],
            ),
          );
        },
      ),
    );
  }
}
