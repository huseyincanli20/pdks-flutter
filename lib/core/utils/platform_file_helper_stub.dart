import 'package:url_launcher/url_launcher.dart';

Future<void> platformSaveAndOpenFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    final uri = Uri.parse('data:$mimeType;charset=utf-8,${Uri.encodeComponent(content)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    // Fallback if needed
  }
}
