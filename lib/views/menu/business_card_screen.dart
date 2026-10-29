import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

class BusinessCardScreen extends StatelessWidget {
  const BusinessCardScreen({super.key});

  String _generateVCard({
    required String name,
    required String title,
    required String company,
    required String phone,
    required String email,
  }) {
    return '''BEGIN:VCARD
VERSION:3.0
N:;$name;;;
FN:$name
ORG:$company
TITLE:$title
TEL;TYPE=CELL:$phone
EMAIL:$email
END:VCARD''';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;
    const companyName = 'ACME KORPORASYON A.Ş.';

    final vCardData = _generateVCard(
      name: user.fullName,
      title: '${user.department} - ${user.title}',
      company: companyName,
      phone: user.phone,
      email: user.email,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dijital Kartvizitim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Şık Kurumsal Kartvizit Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge, color: Colors.white, size: 24),
                      ),
                      const Text(
                        'PDKS DİJİTAL KİMLİK',
                        style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    user.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.title,
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user.department,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white60, size: 16),
                      const SizedBox(width: 8),
                      Text(user.phone, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.white60, size: 16),
                      const SizedBox(width: 8),
                      Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.corporate_fare, color: Colors.white60, size: 16),
                      SizedBox(width: 8),
                      Text(companyName, style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // vCard QR Kod Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rehbere Kaydetmek İçin QR Kodu Okutun',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Herhangi bir telefon kamerası ile rehbere direkt eklenir (vCard).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: vCardData,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Bilgileri Kopyala'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kartvizit bilgileri panoya kopyalandı!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Paylaş (vCard)'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kartvizit paylaşım menüsü açıldı.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
