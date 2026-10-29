import 'platform_file_helper_stub.dart'
    if (dart.library.html) 'platform_file_helper_web.dart' as helper;

class PlatformFileHelper {
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
