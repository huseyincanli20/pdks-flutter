import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
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
    const companyName = 'ACME TEKNOLOJİ VE HOLDİNG A.Ş.';

    final vCardData = _generateVCard(
      name: user.fullName,
      title: '${user.department} - ${user.title}',
      company: companyName,
      phone: user.phone,
      email: user.email,
    );

    Color badgeColor;
    String badgeTitle;
    switch (user.role) {
      case UserRole.boss:
        badgeColor = const Color(0xFFF59E0B);
        badgeTitle = 'YÖNETİM KURULU / CEO';
        break;
      case UserRole.admin:
        badgeColor = const Color(0xFFA855F7);
        badgeTitle = 'SİSTEM YÖNETİCİSİ';
        break;
      case UserRole.hr:
        badgeColor = const Color(0xFF38BDF8);
        badgeTitle = 'İNSAN KAYNAKLARI DİREKTÖRLÜĞÜ';
        break;
      case UserRole.employee:
      default:
        badgeColor = const Color(0xFF60A5FA);
        badgeTitle = 'KURUMSAL ÇALIŞAN';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dijital Kartvizitim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            // Apple Wallet / Samsung Wallet Tarzı Dijital Kartvizit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0A0F1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PDKS PASS',
                                style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                badgeTitle,
                                style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.nfc_rounded, color: Colors.white38, size: 28),
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
                    style: TextStyle(color: badgeColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user.department,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: Colors.white60, size: 16),
                      const SizedBox(width: 10),
                      Text(user.phone, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: Colors.white60, size: 16),
                      const SizedBox(width: 10),
                      Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.apartment_rounded, color: Colors.white60, size: 16),
                      SizedBox(width: 10),
                      Text(companyName, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // vCard QR Kod Kartı (Rehbere Ekleme)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Rehbere Kaydetmek İçin Okutun',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'iPhone veya Samsung kamera uygulamasıyla okutulduğunda vCard olarak rehbere eklenir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: vCardData,
                      version: QrVersions.auto,
                      size: 190.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Kartvizit bağlantısı panoya kopyalandı.'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.contact_page_rounded, size: 18),
                          label: const Text('Rehbere Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                content: Text('Kişi kartvizit verisi (.vcf) oluşturuldu.'),
                              ),
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
