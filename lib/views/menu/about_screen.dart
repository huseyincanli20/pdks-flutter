import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında & Sistem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 54),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDKS Enterprise',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sürüm 1.0.0 (Build 2026.10.1)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uygulama Mimarisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 10),
                  Text(
                    'Bu sistem; çalışanların ofis, şantiye ve uzaktan çalışma alanlarındaki devam ve mesailerini güvenli bir şekilde takip etmek üzere Flutter & .NET altyapısıyla geliştirilmiştir.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Text('Aktif Güvenlik Katmanları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('• 10s Dinamik HMAC-SHA256 Token (QR Anti-Cheat)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('• Haversine GPS Geofencing (150m Ofis Yarıçapı)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('• Android & iOS Mock Location (Sahte GPS) Filtresi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('• Biometric FaceID & Local Authentication', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KVKK ve Veri Güvenliği', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 8),
                  Text(
                    'Konum verileri sadece check-in ve check-out anında anlık mesafe doğrulaması amacıyla işlenir. Mesai dışında sürekli arka plan konum takibi yapılmamaktadır.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
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
}
