/// Stub for non-web environments (unit tests / native without web)
Future<void> platformTriggerWebNotification({
  required String title,
  required String body,
  String? icon,
}) async {
  // Fallback for native/testing
}

Future<void> platformPlayIosChime() async {
  // Fallback
}
