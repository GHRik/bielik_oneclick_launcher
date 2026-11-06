import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/chat/chat_page.dart';
import 'package:bielik_oneclick_launcher/chat/controllers/chat_workspace.dart';
import 'package:bielik_oneclick_launcher/home_page/widgets/model_management_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _chatWorkspace = ChatWorkspace();

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(workspace: _chatWorkspace),
      ),
    );
  }

  @override
  void dispose() {
    _chatWorkspace.dispose();
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
                        child: const ModelManagementPanel(),
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
                  onPressed: _openChat,
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
