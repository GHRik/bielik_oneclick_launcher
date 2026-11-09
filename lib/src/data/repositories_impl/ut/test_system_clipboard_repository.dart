import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/system_clipboard_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  bool fail = false;
  const repository = SystemClipboardRepository();

  setUp(() {
    calls = [];
    fail = false;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      if (fail) throw PlatformException(code: 'clipboard_unavailable');
      return null;
    });
  });
  tearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  test(
    'Copies the complete text without changing whitespace or Unicode',
    () async {
      const text = '  Zażółć 🙂\n\nCałe pytanie?  ';
      await repository.copyText(text);
      expect(calls.single.method, 'Clipboard.setData');
      expect(calls.single.arguments, {'text': text});
    },
  );

  test('Propagates system clipboard failures', () async {
    fail = true;
    await expectLater(
      repository.copyText('Text'),
      throwsA(isA<PlatformException>()),
    );
  });
}
