import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import 'cafeteria_shell.dart';

class CafeteriaMenuViewScreen extends StatelessWidget {
  const CafeteriaMenuViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final menu = pdks.todayMenu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = pdks.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Günün Yemekhane Menüsü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // Eğer giriş yapan kullanıcı Yemekhane Şefi, İK veya Patron ise menüyü düzenleme kısayolu
          if (user.role == UserRole.cafeteria || user.role == UserRole.hr || user.role == UserRole.boss || user.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Menüyü Düzenle',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaShell()));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          16,
          18,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Tarih ve Şef Başlığı Banner'ı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(menu.date),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 ~${menu.totalCalories} kcal',
                          style: const TextStyle(color: Color(0xFFEA580C), fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ÖĞLE YEMEĞİ MENÜSÜ',
                    style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Afiyet Olsun! 🍽️',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.soup_kitchen_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hazırlayan: ${menu.updatedBy}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Bugünün Lezzetleri',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
            ),
            const SizedBox(height: 12),

            // 1. Çorba
            _buildMenuItemCard(
              context: context,
              category: 'GÜNÜN ÇORBASI',
              name: menu.soup,
              icon: Icons.soup_kitchen_outlined,
              color: const Color(0xFFF59E0B),
              calorieHint: '160 kcal',
            ),
            const SizedBox(height: 10),

            // 2. Ana Yemek
            _buildMenuItemCard(
              context: context,
              category: 'ANA YEMEK',
              name: menu.mainDish,
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFEF4444),
              calorieHint: '380 kcal',
            ),
            const SizedBox(height: 10),

            // 3. Yan Yemek / Pilav / Makarna
            _buildMenuItemCard(
              context: context,
              category: 'YAN YEMEK / GARNİTÜR',
              name: menu.sideDish,
              icon: Icons.rice_bowl_outlined,
              color: const Color(0xFF10B981),
              calorieHint: '210 kcal',
            ),
            const SizedBox(height: 10),

            // 4. Tatlı / Meyve / Salata
            _buildMenuItemCard(
              context: context,
              category: 'TATLI / MEYVE / SALATA',
              name: menu.dessertOrSalad,
              icon: Icons.icecream_outlined,
              color: const Color(0xFFEC4899),
              calorieHint: '140 kcal',
            ),
            const SizedBox(height: 10),

            // 5. İçecek
            _buildMenuItemCard(
              context: context,
              category: 'İÇECEK',
              name: menu.drink,
              icon: Icons.local_drink_outlined,
              color: const Color(0xFF0284C7),
              calorieHint: '70 kcal',
            ),

            const SizedBox(height: 20),

            // Vejetaryen Alternatif
            if (menu.vegetarianAlternative != null && menu.vegetarianAlternative!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VEJETARYEN & DİYET ALTERNATİFİ',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            menu.vegetarianAlternative!,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Şefin Notu
            if (menu.chefNote != null && menu.chefNote!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Şefin Notu & Alerjen Bilgisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                          const SizedBox(height: 3),
                          Text(
                            menu.chefNote!,
                            style: TextStyle(color: AppColors.textSub(context), fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Yemekhane Saatleri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeInfo('Öğle Servisi', '12:00 - 14:00', Icons.schedule_rounded),
                  Container(width: 1, height: 36, color: AppColors.cardBorder(context)),
                  _buildTimeInfo('Akşam Servisi', '18:00 - 19:30', Icons.dinner_dining_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard({
    required BuildContext context,
    required String category,
    required String name,
    required IconData icon,
    required Color color,
    required String calorieHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              calorieHint,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String title, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFEA580C)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
