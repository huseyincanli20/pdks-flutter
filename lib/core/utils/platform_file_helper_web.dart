// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

Future<void> platformSaveAndOpenFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    // vCard ise iPhone / Android Safari'nin doğrudan Kişiler (Contacts) sayfasını açması için
    if (fileName.endsWith('.vcf') || mimeType.contains('vcard')) {
      html.window.open(url, '_blank');
    }

    // Kısa süre sonra bellek temizliği
    Future.delayed(const Duration(seconds: 15), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (e) {
    // Web fallback
  }
}

Future<({String name, String size, String? path, String? base64Data})?> platformPickDocumentFile() async {
  final completer = Completer<({String name, String size, String? path, String? base64Data})?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.pdf,.doc,.docx,.xls,.xlsx,.txt,.png,.jpg,.jpeg';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final sizeFormatted = file.size > 1024 * 1024
            ? '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(file.size / 1024).toStringAsFixed(0)} KB';
        completer.complete((
          name: file.name,
          size: sizeFormatted,
          path: null,
          base64Data: reader.result?.toString(),
        ));
      });
      reader.readAsDataUrl(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
