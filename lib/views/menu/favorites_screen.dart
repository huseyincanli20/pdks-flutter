import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../mobile/leave_request_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _showInfoDialog(BuildContext context, String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sık Kullanılanlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'HIZLI KISAYOLLAR & KURUMSAL SERVİSLER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1),
            ),
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.beach_access_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Hızlı İzin Talebi',
            subtitle: 'Yıllık izin veya mazeret talebi oluşturun',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.restaurant_rounded,
            color: const Color(0xFF10B981),
            title: 'Günün Yemek Menüsü',
            subtitle: 'Süzme mercimek, ızgara tavuk, pilav & meyve',
            onTap: () {
              _showInfoDialog(
                context,
                'Günün Yemek Menüsü',
                'Bugün şirket yemekhanemizde:\n\n• Süzme Mercimek Çorbası\n• Izgara Tavuk Fileto & Garnitür\n• Tereyağlı Pirinç Pilavı\n• Akdeniz Yeşillikleri Salatası\n• Mevsim Meyvesi & Ayran\n\nAfiyet olsun!',
                Icons.restaurant_rounded,
                const Color(0xFF10B981),
              );
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.directions_bus_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Şirket Servis Saatleri',
            subtitle: 'Kadıköy, Beşiktaş ve Bakırköy akşam güzergahları',
            onTap: () {
              _showInfoDialog(
                context,
                'Şirket Servis Saatleri',
                'Akşam Çıkış Servisleri (Kalkış: 18:15):\n\n1. Hat: Maslak - Levent - Zincirlikuyu - Kadıköy\n2. Hat: Maslak - Çağlayan - Mecidiyeköy - Bakırköy\n3. Hat: Maslak - Kozyatağı - Ataşehir - Ümraniye\n4. Hat: Maslak - Kağıthane - Eyüp - Gaziosmanpaşa\n\nServis Sorumlusu İletişim: 0532 000 11 22',
                Icons.directions_bus_rounded,
                const Color(0xFF3B82F6),
              );
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF6366F1),
            title: 'Resmi Tatiller Takvimi',
            subtitle: '2026 yılı resmi tatil günleri ve köprü tatilleri',
            onTap: () {
              _showInfoDialog(
                context,
                '2026 Resmi Tatil Günleri',
                '• 1 Ocak (Perşembe): Yılbaşı\n• 23 Nisan (Perşembe): Ulusal Egemenlik ve Çocuk Bayramı\n• 1 Mayıs (Cuma): Emek ve Dayanışma Günü\n• 19 Mayıs (Salı): Atatürk\'ü Anma, Gençlik ve Spor Bayramı\n• 15 Temmuz (Çarşamba): Demokrasi ve Milli Birlik Günü\n• 30 Ağustos (Pazar): Zafer Bayramı\n• 29 Ekim (Perşembe): Cumhuriyet Bayramı',
                Icons.calendar_month_rounded,
                const Color(0xFF6366F1),
              );
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.medical_services_outlined,
            color: const Color(0xFFEF4444),
            title: 'İş Yeri Hekimi & Revir',
            subtitle: 'Revir mesai saatleri ve acil durum dahili hatları',
            onTap: () {
              _showInfoDialog(
                context,
                'Revir & Acil Durum',
                'İş Yeri Hekimi: Dr. Mehmet Yılmaz\nÇalışma Saatleri: Hafta içi 09:00 - 17:30\nKonum: B Blok, Giriş Kat, Oda No: 104\n\nAcil Dahili Hatlar:\n• Revir: Dahili 1044\n• İK Masası: Dahili 1002\n• Güvenlik Masası: Dahili 1000\n• Genel Acil Çağrı: 112',
                Icons.medical_services_outlined,
                const Color(0xFFEF4444),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
