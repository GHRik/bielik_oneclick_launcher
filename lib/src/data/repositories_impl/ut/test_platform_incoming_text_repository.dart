import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/platform_incoming_text_repository.dart';

class _Channel extends Fake implements EventChannel {
  _Channel(this.events);
  final Stream<dynamic> events;
  @override
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) => events;
}

void main() {
  group('PlatformIncomingTextRepository', () {
    Future<List<String>> receive(List<dynamic> events) =>
        PlatformIncomingTextRepository(
          channel: _Channel(Stream.fromIterable(events)),
        ).incomingText.toList();

    test('Forwards text without altering its formatting', () async {
      expect(await receive(['  Zażółć\nBielik  ']), ['  Zażółć\nBielik  ']);
    });

    test('Rejects non-text platform payloads', () async {
      expect(
        await receive([
          42,
          null,
          {'text': 'invalid'},
        ]),
        isEmpty,
      );
    });

    test('Rejects empty selections', () async {
      expect(await receive(['', ' \n ']), isEmpty);
    });

    test('Rejects oversized selections', () async {
      expect(await receive(['x' * 65537]), isEmpty);
    });

    test('Accepts a selection at the size limit', () async {
      expect((await receive(['x' * 65536])).single.length, 65536);
    });
  });
}
