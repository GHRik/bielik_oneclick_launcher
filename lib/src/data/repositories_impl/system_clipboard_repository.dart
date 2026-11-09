import 'package:flutter/services.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/clipboard_repository.dart';

class SystemClipboardRepository implements ClipboardRepository {
  const SystemClipboardRepository();

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
