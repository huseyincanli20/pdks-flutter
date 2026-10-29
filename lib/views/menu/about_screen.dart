import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hakkında', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          children: [
            // Uygulama Başlığı ve Logosu
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDKS Enterprise',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Sürüm 1.0.0 (Build 2026.10.1)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Mimari Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Uygulama Mimarisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bu sistem; çalışanların ofis, şantiye ve uzaktan çalışma alanlarındaki devam ve mesailerini güvenli bir şekilde takip etmek üzere Flutter & Modern Cross-Platform altyapısıyla geliştirilmiştir.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  const Text('Aktif Güvenlik Katmanları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildBulletPoint('10s Dinamik HMAC-SHA256 Token (QR Anti-Cheat)'),
                  _buildBulletPoint('Haversine GPS Geofencing (150m Ofis Yarıçapı)'),
                  _buildBulletPoint('Android & iOS Mock Location (Sahte GPS) Filtresi'),
                  _buildBulletPoint('Apple FaceID & Android Biometric Doğrulama'),
                  _buildBulletPoint('Ofis Wi-Fi BSSID / Kurumsal IP Kontrolü'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // KVKK ve Gizlilik Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('KVKK ve Veri Gizliliği', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Konum verileri sadece check-in ve check-out butonuna tıklandığı an mesafeyi teyit etmek için anlık olarak işlenir. Mesai saatleri dışında veya arka planda sürekli konum takibi kesinlikle yapılmaz.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text(
              '© 2026 Tüm Hakları Saklıdır.\nKurumsal PDKS Çözümleri A.Ş.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
