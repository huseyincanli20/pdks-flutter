import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';

Future<bool> downloadCsvFile(String fileName, String csvContent) {
  return triggerPlatformCsvDownload(fileName, csvContent);
}
