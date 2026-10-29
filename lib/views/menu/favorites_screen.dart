import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../mobile/leave_request_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sık Kullanılanlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Hızlı Kısayollar ve Servisler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          _buildFavoriteCard(
            context,
            icon: Icons.beach_access,
            color: Colors.orange,
            title: 'Hızlı İzin Talebi',
            subtitle: 'Yıllık izin veya mazeret talebi oluşturun',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()));
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.restaurant_menu,
            color: Colors.teal,
            title: 'Günün Yemek Menüsü',
            subtitle: 'Mercimek Çorbası, Izgara Tavuk, Pilav, Meyve',
            onTap: () {
              _showInfoDialog(context, 'Günün Menüsü', 'Bugün yemekhanemizde:\n\n• Süzme Mercimek Çorbası\n• Izgara Tavuk Fileto\n• Şehriyeli Pirinç Pilavı\n• Mevsim Salatası & Ayran\n\nAfiyet olsun!');
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.directions_bus_outlined,
            color: Colors.blue,
            title: 'Şirket Servis Saatleri',
            subtitle: 'Kadıköy, Beşiktaş ve Bakırköy güzergahları',
            onTap: () {
              _showInfoDialog(context, 'Servis Güzergahları', 'Akşam Çıkış Servisleri (18:15):\n\n1. Hat: Maslak - Levent - Beşiktaş - Kadıköy\n2. Hat: Maslak - Mecidiyeköy - Bakırköy\n3. Hat: Maslak - Ataşehir - Ümraniye');
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.calendar_month,
            color: Colors.indigo,
            title: 'Resmi Tatiller & İzin Takvimi',
            subtitle: '2026 yılı resmi tatil ve bayram günleri',
            onTap: () {
              _showInfoDialog(context, '2026 Resmi Tatiller', '• 1 Ocak: Yılbaşı\n• 23 Nisan: Ulusal Egemenlik ve Çocuk Bayramı\n• 1 Mayıs: Emek ve Dayanışma Günü\n• 19 Mayıs: Atatürk\'ü Anma ve Gençlik Bayramı\n• 29 Ekim: Cumhuriyet Bayramı');
            },
          ),

          _buildFavoriteCard(
            context,
            icon: Icons.contact_phone_outlined,
            color: Colors.redAccent,
            title: 'Acil Durum & İK Destek',
            subtitle: 'İş yeri hekimi, revir ve İK acil hattı',
            onTap: () {
              _showInfoDialog(context, 'Acil İletişim', 'İş Yeri Hekimi: Dahili 1044\nİnsan Kaynakları Masası: Dahili 1002\nGüvenlik & Turnike Masası: Dahili 1000\nAcil Çağrı: 112');
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
