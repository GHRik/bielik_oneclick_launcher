import 'dart:async';

import 'package:flutter/services.dart';

/// Asks Android 13+ for permission to post notifications. Without it the
/// download plugin cannot show the progress of a model download outside the
/// app.
class NotificationPermissionDataSource {
  const NotificationPermissionDataSource({
    this.channel = const MethodChannel('bielik/notification_permission'),
    this.timeout = const Duration(minutes: 1),
  });

  final MethodChannel channel;

  /// The longest wait for an answer, so that a lost reply cannot hold up the
  /// download.
  final Duration timeout;

  /// Shows the system dialog when the permission is neither granted nor
  /// permanently denied, and completes once the user has answered. A refusal
  /// or a platform without this channel is not an error: the download goes on
  /// without a notification.
  Future<void> request() async {
    try {
      await channel.invokeMethod<bool>('request').timeout(timeout);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    } on TimeoutException {
      return;
    }
  }
}
