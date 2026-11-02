import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> platformSaveBytes({required String fileName, required Uint8List bytes, required String mimeType}) async {
  await FilePicker.saveFile(dialogTitle: 'Dosyayı kaydet', fileName: fileName, bytes: bytes);
}

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

Future<({String name, String size, String? path, String? base64Data})?> platformPickDocumentFile() async {
  return null;
}
