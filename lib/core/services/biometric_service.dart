import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Biyometrik donanım mevcut mu? (FaceID, Fingerprint vb.)
  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false; // Web'de local_auth doğrudan çalışmaz, PIN kullanılır
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  // Biyometrik doğrulama isteği aç
  static Future<bool> authenticate({String reason = 'PDKS Giriş/Çıkışını Onaylayın'}) async {
    if (kIsWeb) return true;
    try {
      final available = await isBiometricAvailable();
      if (!available) return true; // Cihaz desteklemiyorsa PIN'e düş

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
}
