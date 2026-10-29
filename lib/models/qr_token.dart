import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrToken {
  final int companyId;
  final String locationId;
  final int timestampSeconds;
  final String nonce;
  final String signature;

  QrToken({
    required this.companyId,
    required this.locationId,
    required this.timestampSeconds,
    required this.nonce,
    required this.signature,
  });

  // Dinamik güvenli QR kod içeriği üretici
  static String generateSecurePayload({
    required int companyId,
    required String locationId,
    required String secretKey,
  }) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Her 10 saniyede bir periyot değişir
    final period = nowSeconds ~/ 10;
    final rawData = '$companyId:$locationId:$period';
    final bytes = utf8.encode(rawData + secretKey);
    final hash = sha256.convert(bytes).toString().substring(0, 16);

    final payloadMap = {
      'c': companyId,
      'l': locationId,
      't': nowSeconds,
      's': hash,
    };

    return jsonEncode(payloadMap);
  }

  // QR kodunun geçerliliğini ve süresini doğrulama
  static bool verifyPayload(String payloadJson, String secretKey, {int maxAgeSeconds = 15}) {
    try {
      final map = jsonDecode(payloadJson) as Map<String, dynamic>;
      final int c = map['c'];
      final String l = map['l'];
      final int t = map['t'];
      final String s = map['s'];

      final currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((currentSeconds - t).abs() > maxAgeSeconds) {
        return false; // QR süresi dolmuş (Ekran görüntüsü alınmış olabilir)
      }

      final period = t ~/ 10;
      final rawData = '$c:$l:$period';
      final bytes = utf8.encode(rawData + secretKey);
      final expectedHash = sha256.convert(bytes).toString().substring(0, 16);

      return s == expectedHash;
    } catch (_) {
      return false;
    }
  }
}
