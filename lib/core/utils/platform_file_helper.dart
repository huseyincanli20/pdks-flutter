import 'dart:typed_data';
import 'platform_file_helper_stub.dart'
    if (dart.library.html) 'platform_file_helper_web.dart' as helper;

class PlatformFileHelper {
  static Future<void> saveBytes({required String fileName, required Uint8List bytes, required String mimeType}) =>
      helper.platformSaveBytes(fileName: fileName, bytes: bytes, mimeType: mimeType);
  static Future<void> saveAndOpen({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    await helper.platformSaveAndOpenFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
  }

  static Future<({String name, String size, String? path, String? base64Data})?> pickDocumentFile() async {
    return await helper.platformPickDocumentFile();
  }
}
