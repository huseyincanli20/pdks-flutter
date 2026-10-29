// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

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
