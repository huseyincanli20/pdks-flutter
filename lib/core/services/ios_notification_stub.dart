import 'package:flutter/services.dart';

const MethodChannel _appleNotificationChannel =
    MethodChannel('com.example.pdks_flutter/apple_notifications');

/// Apple iOS Yerel Bildirim Merkezinde (UNUserNotificationCenter) bildirim oluştur
Future<void> platformTriggerWebNotification({
  required String title,
  required String body,
  String? icon,
}) async {
  try {
    await _appleNotificationChannel.invokeMethod('showAppleNotification', {
      'title': title,
      'body': body,
    });
  } catch (_) {
    // Non-iOS or test environment
  }
}

Future<void> platformPlayIosChime() async {
  // Native iOS handles sounds directly through UNNotificationSound.default
}

Future<bool> platformRequestNotificationPermission() async {
  try {
    final granted =
        await _appleNotificationChannel.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  } catch (_) {}
  return false;
}

String platformGetNotificationPermissionStatus() {
  return 'granted';
}
