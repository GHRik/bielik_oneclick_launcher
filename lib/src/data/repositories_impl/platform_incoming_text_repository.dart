import 'package:flutter/services.dart';

import 'package:bielik_oneclick_launcher/src/domain/repositories/incoming_text_repository.dart';

class PlatformIncomingTextRepository implements IncomingTextRepository {
  PlatformIncomingTextRepository({
    EventChannel channel = const EventChannel('bielik/incoming_text'),
  }) : incomingText = channel
           .receiveBroadcastStream()
           .where(
             (event) =>
                 event is String &&
                 event.trim().isNotEmpty &&
                 event.length <= 65536,
           )
           .cast<String>();

  @override
  final Stream<String> incomingText;
}
