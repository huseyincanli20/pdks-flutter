class WifiNetworkVerificationResult {
  final bool isVerified;
  final String networkName;
  final String ipAddress;
  final String? message;

  WifiNetworkVerificationResult({
    required this.isVerified,
    required this.networkName,
    required this.ipAddress,
    this.message,
  });
}

class WifiNetworkService {
  // Şirket için izin verilen Wi-Fi SSID veya IP blokları
  static const List<String> allowedSsids = ['Sirket_Guest', 'Sirket_Personel', 'Company_5G'];

  static Future<WifiNetworkVerificationResult> verifyOfficeNetwork({
    String? currentSsid,
  }) async {
    // Simüle edilmiş ya da ağ eklentisi ile elde edilen ağ doğrulama
    final ssid = currentSsid ?? 'Sirket_Personel';
    final isAllowed = allowedSsids.contains(ssid);

    return WifiNetworkVerificationResult(
      isVerified: isAllowed,
      networkName: ssid,
      ipAddress: '192.168.1.105',
      message: isAllowed
          ? 'Kurumsal Wi-Fi ağı doğrulandı ($ssid)'
          : 'HATA: Kurumsal Wi-Fi ağına bağlı değilsiniz! Lütfen şirket ağına bağlanın.',
    );
  }
}
