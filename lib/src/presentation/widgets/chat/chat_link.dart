import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openChatLink(BuildContext context, String? href) async {
  final uri = Uri.tryParse(href?.trim() ?? '');
  final supported =
      uri != null &&
      (({'http', 'https'}.contains(uri.scheme) && uri.host.isNotEmpty) ||
          (uri.scheme == 'mailto' && uri.path.isNotEmpty));
  if (supported) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The platform can reject a link or have no matching application.
    }
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        supported
            ? 'Nie udało się otworzyć linku.'
            : 'Ten link nie zawiera obsługiwanego adresu.',
      ),
    ),
  );
}
