import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cafeteria_menu.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';
import '../notifications/notifications_screen.dart';
import 'two_week_menu_publisher_screen.dart';
import 'cafeteria_menu_view_screen.dart';

class CafeteriaShell extends StatefulWidget {
  const CafeteriaShell({super.key});

  @override
  State<CafeteriaShell> createState() => _CafeteriaShellState();
}

class _CafeteriaShellState extends State<CafeteriaShell> {
  late TextEditingController _soupCtrl;
  late TextEditingController _mainDishCtrl;
  late TextEditingController _sideDishCtrl;
  late TextEditingController _dessertCtrl;
  late TextEditingController _drinkCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _vegCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final pdks = context.read<PdksState>();
    final menu = pdks.todayMenu;

    _soupCtrl = TextEditingController(text: menu.soup);
    _mainDishCtrl = TextEditingController(text: menu.mainDish);
    _sideDishCtrl = TextEditingController(text: menu.sideDish);
    _dessertCtrl = TextEditingController(text: menu.dessertOrSalad);
    _drinkCtrl = TextEditingController(text: menu.drink);
    _caloriesCtrl = TextEditingController(text: menu.totalCalories.toString());
    _vegCtrl = TextEditingController(text: menu.vegetarianAlternative ?? '');
    _noteCtrl = TextEditingController(text: menu.chefNote ?? '');
  }

  @override
  void dispose() {
    _soupCtrl.dispose();
    _mainDishCtrl.dispose();
    _sideDishCtrl.dispose();
    _dessertCtrl.dispose();
    _drinkCtrl.dispose();
    _caloriesCtrl.dispose();
    _vegCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveMenu() {
    final pdks = context.read<PdksState>();
    final updated = CafeteriaMenu(
      date: DateTime.now(),
      soup: _soupCtrl.text.trim().isEmpty ? 'Süzme Mercimek Çorbası' : _soupCtrl.text.trim(),
      mainDish: _mainDishCtrl.text.trim().isEmpty ? 'Hasanpaşa Köfte' : _mainDishCtrl.text.trim(),
      sideDish: _sideDishCtrl.text.trim().isEmpty ? 'Tereyağlı Pirinç Pilavı' : _sideDishCtrl.text.trim(),
      dessertOrSalad: _dessertCtrl.text.trim().isEmpty ? 'Mevsim Salata & Kazandibi' : _dessertCtrl.text.trim(),
      drink: _drinkCtrl.text.trim().isEmpty ? 'Ayran / Su' : _drinkCtrl.text.trim(),
      totalCalories: int.tryParse(_caloriesCtrl.text.trim()) ?? 820,
      vegetarianAlternative: _vegCtrl.text.trim().isEmpty ? null : _vegCtrl.text.trim(),
      chefNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      updatedBy: pdks.currentUser.fullName,
    );

    pdks.updateTodayMenu(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Text('Günün yemekhane menüsü kaydedildi ve tüm personele duyuruldu! 🍽️'),
      ),
    );
  }

  void _applyTemplate(String soup, String mainDish, String side, String dessert, String veg, int cal) {
    setState(() {
      _soupCtrl.text = soup;
      _mainDishCtrl.text = mainDish;
      _sideDishCtrl.text = side;
      _dessertCtrl.text = dessert;
      _vegCtrl.text = veg;
      _caloriesCtrl.text = cal.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('"$mainDish" şablonu yüklendi.'),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Oturumu Kapat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Yemekhane yönetim panelinden çıkış yapmak istediğinize emin misiniz?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final pdks = context.read<PdksState>();
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              pdks.logout();
            },
            child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Geri Dön',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yemekhane Yönetim Paneli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${user.fullName} (${user.title})', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded),
            tooltip: '2 Haftalık Menü Yayınla',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TwoWeekMenuPublisherScreen()),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (pdks.unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            tooltip: 'Bildirimler',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Oturumu Kapat',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canlı Yemekhane Sayaç Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BUGÜNKÜ YEMEK SERVİSİ',
                        style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()),
                          style: const TextStyle(color: Color(0xFFFB923C), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Servis Edilen Porsiyon', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 4),
                          Text('148 Kişi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tahmini Kalan Kapasite', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 4),
                          Text('52 Porsiyon', style: TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2 Haftalık Menü Yayınlama Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2 Haftalık Menü Yayınlama',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '14 günlük yemek takvimini tek ekrandan yönetin',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Önümüzdeki 2 haftanın çorba, ana yemek, yan yemek, tatlı ve vejetaryen alternatiflerini planlayın ve personele bildirim olarak duyurun.',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFEA580C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: const Text(
                            '2 Haftalık Menüyü Yayınla',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TwoWeekMenuPublisherScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Çizelge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen(initialTabIndex: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Şablon Menüler
            Text(
              'Hızlı Menü Şablonları',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTemplateChip(
                    'Geleneksel Türk',
                    'Ezogelin Çorbası',
                    'Hünkar Beğendi',
                    'Pirinç Pilavı',
                    'Fırın Sütlaç',
                    'Zeytinyağlı Taze Fasulye',
                    860,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Kebap Günü',
                    'Mercimek Çorbası',
                    'Adana / Urfa Kebap',
                    'Bulgur Pilavı & Köz',
                    'Künefe / Baklava',
                    'Mantar Sote',
                    920,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'İtalyan Mutfağı',
                    'Domates Çorbası',
                    'Fırın Tavuk Parmigiana',
                    'Fettuccine Alfredo',
                    'Tiramisu',
                    'Sebzeli Lazanya',
                    790,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Hafif & Akdeniz',
                    'Köz Patlıcan Çorbası',
                    'Fırında Somon / Levrek',
                    'Kinoa & Mevsim Yeşillikleri',
                    'Meyve Salatası',
                    'Zeytinyağlı Enginar',
                    640,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menü Düzenleme Formu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFFEA580C), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Günün Menüsünü Belirle',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Yayınlandığında tüm personelin ana sayfasına yansır',
                              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. Çorba
                  _buildMenuInputField(
                    label: 'Günün Çorbası',
                    hint: 'Örn: Süzme Mercimek Çorbası, Ezogelin',
                    controller: _soupCtrl,
                    icon: Icons.soup_kitchen_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 14),

                  // 2. Ana Yemek
                  _buildMenuInputField(
                    label: 'Ana Yemek',
                    hint: 'Örn: Hasanpaşa Köfte, Orman Kebabı, Fırın Tavuk',
                    controller: _mainDishCtrl,
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 14),

                  // 3. Yan Yemek / Garnitür
                  _buildMenuInputField(
                    label: 'Yan Yemek / Pilav / Makarna',
                    hint: 'Örn: Tereyağlı Pirinç Pilavı, Soslu Spagetti',
                    controller: _sideDishCtrl,
                    icon: Icons.rice_bowl_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),

                  // 4. Tatlı / Meyve / Salata
                  _buildMenuInputField(
                    label: 'Tatlı / Meyve / Salata',
                    hint: 'Örn: Kazandibi, Mevsim Salata, Elma',
                    controller: _dessertCtrl,
                    icon: Icons.icecream_rounded,
                    color: const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 14),

                  // 5. İçecek & Kalori
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuInputField(
                          label: 'İçecek',
                          hint: 'Ayran / Su',
                          controller: _drinkCtrl,
                          icon: Icons.local_drink_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuInputField(
                          label: 'Toplam Kalori (kcal)',
                          hint: '820',
                          controller: _caloriesCtrl,
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Vejetaryen Alternatif
                  _buildMenuInputField(
                    label: 'Vejetaryen Alternatif (Opsiyonel)',
                    hint: 'Örn: Zeytinyağlı Enginar & Fırın Sebze',
                    controller: _vegCtrl,
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),

                  // 7. Şefin Notu
                  _buildMenuInputField(
                    label: 'Şefin Notu / Alerjen Uyarısı',
                    hint: 'Örn: Glüten ve laktoz içerir. Afiyet olsun.',
                    controller: _noteCtrl,
                    icon: Icons.edit_note_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 20),
                      label: const Text(
                        'Menüyü Kaydet ve Personele Yayınla',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _saveMenu,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Yemekhane Panelinden Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _showLogoutDialog,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
            filled: true,
            fillColor: AppColors.inputBg(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String title, String soup, String mainDish, String side, String dessert, String veg, int cal) {
    return ActionChip(
      avatar: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFEA580C)),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: () => _applyTemplate(soup, mainDish, side, dessert, veg, cal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.cardBg(context),
      side: BorderSide(color: AppColors.cardBorder(context)),
    );
  }
}
