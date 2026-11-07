import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/presentation/formatters/storage_size_formatter.dart';

void main() {
  group('Storage size formatting', () {
    for (final entry in <int, String>{
      999: '999 B',
      1000: '1,0 KB',
      1000000: '1,0 MB',
      1000000000: '1,0 GB',
    }.entries) {
      test('Formats ${entry.key} bytes as ${entry.value}', () {
        expect(StorageSizeFormatter.format(entry.key), entry.value);
      });
    }
  });
}
