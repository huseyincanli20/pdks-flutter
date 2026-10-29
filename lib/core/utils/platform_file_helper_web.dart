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
  
  // iOS Safari ve modern tarayıcılar için kabul edilen tüm belgeler
  uploadInput.accept = '*/*';
  
  // ÖNEMLİ (iOS Safari & WebKit Düzeltmesi): 
  // 1. Kesinlikle 'pointer-events: none' olmamalıdır (Safari tıklamayı geçersiz kılar).
  // 2. Ekran dışı (-9999px) yerine görünmez ama DOM içinde 0,0 noktasında tutulur.
  // 3. Ekrana banner ve modal gelmeden önce doğrudan click() sinyali gönderilir.
  uploadInput.style.position = 'fixed';
  uploadInput.style.left = '0';
  uploadInput.style.top = '0';
  uploadInput.style.width = '1px';
  uploadInput.style.height = '1px';
  uploadInput.style.opacity = '0.01';
  uploadInput.style.zIndex = '-9999';

  html.document.body?.children.add(uploadInput);

  bool isHandled = false;
  void cleanup() {
    if (!isHandled) {
      isHandled = true;
      try {
        uploadInput.remove();
      } catch (_) {}
    }
  }

  // Kullanıcı dosya seçtiğinde tetiklenir
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      
      reader.onLoadEnd.listen((e) {
        final sizeFormatted = file.size > 1024 * 1024
            ? '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(file.size / 1024).toStringAsFixed(0)} KB';
            
        cleanup();
        if (!completer.isCompleted) {
          completer.complete((
            name: file.name,
            size: sizeFormatted,
            path: null,
            base64Data: reader.result?.toString(),
          ));
        }
      });

      reader.onError.listen((_) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
      });

      reader.readAsDataUrl(file);
    } else {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }
  });

  // Eşzamanlı olarak doğrudan tıklama sinyali gönder
  uploadInput.click();

  // 3 dakikalık güvenlik zaman aşımı (Kullanıcı telefondan dosya ararken erken sonlanmaz)
  return completer.future.timeout(
    const Duration(minutes: 3),
    onTimeout: () {
      cleanup();
      return null;
    },
  );
}
