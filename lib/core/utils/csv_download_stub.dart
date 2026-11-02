import 'package:flutter/services.dart';

Future<bool> triggerPlatformCsvDownload(String fileName, String csvContent) async {
  await Clipboard.setData(ClipboardData(text: csvContent));
  return true;
}
