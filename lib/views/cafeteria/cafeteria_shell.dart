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
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class CafeteriaShell extends StatefulWidget {
  const CafeteriaShell({super.key});

  @override
  State<CafeteriaShell> createState() => _CafeteriaShellState();
}

class _CafeteriaShellState extends State<CafeteriaShell> {
  late TextEditingController _soupCtrl;
  late TextEditingController _soupCalCtrl;

  late TextEditingController _mainDishCtrl;
  late TextEditingController _mainDishCalCtrl;

  late TextEditingController _sideDishCtrl;
  late TextEditingController _sideDishCalCtrl;

  late TextEditingController _dessertCtrl;
  late TextEditingController _dessertCalCtrl;

  late TextEditingController _drinkCtrl;
  late TextEditingController _drinkCalCtrl;

  late TextEditingController _caloriesCtrl;

  late TextEditingController _vegCtrl;
  late TextEditingController _vegCalCtrl;

  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final pdks = context.read<PdksState>();
    final menu = pdks.todayMenu;

    _soupCtrl = TextEditingController(text: menu.soup);
    _soupCalCtrl = TextEditingController(text: menu.soupCalories.toString());

    _mainDishCtrl = TextEditingController(text: menu.mainDish);
    _mainDishCalCtrl = TextEditingController(text: menu.mainDishCalories.toString());

    _sideDishCtrl = TextEditingController(text: menu.sideDish);
    _sideDishCalCtrl = TextEditingController(text: menu.sideDishCalories.toString());

    _dessertCtrl = TextEditingController(text: menu.dessertOrSalad);
    _dessertCalCtrl = TextEditingController(text: menu.dessertCalories.toString());

    _drinkCtrl = TextEditingController(text: menu.drink);
    _drinkCalCtrl = TextEditingController(text: menu.drinkCalories.toString());

    _caloriesCtrl = TextEditingController(text: menu.totalCalories.toString());

    _vegCtrl = TextEditingController(text: menu.vegetarianAlternative ?? '');
    _vegCalCtrl = TextEditingController(text: menu.vegetarianCalories.toString());

    _noteCtrl = TextEditingController(text: menu.chefNote ?? '');
  }

  @override
  void dispose() {
    _soupCtrl.dispose();
    _soupCalCtrl.dispose();
    _mainDishCtrl.dispose();
    _mainDishCalCtrl.dispose();
    _sideDishCtrl.dispose();
    _sideDishCalCtrl.dispose();
    _dessertCtrl.dispose();
    _dessertCalCtrl.dispose();
    _drinkCtrl.dispose();
    _drinkCalCtrl.dispose();
    _caloriesCtrl.dispose();
    _vegCtrl.dispose();
    _vegCalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _calculateTotalCalories() {
    final s = int.tryParse(_soupCalCtrl.text.trim()) ?? 0;
    final m = int.tryParse(_mainDishCalCtrl.text.trim()) ?? 0;
    final side = int.tryParse(_sideDishCalCtrl.text.trim()) ?? 0;
    final d = int.tryParse(_dessertCalCtrl.text.trim()) ?? 0;
    final dr = int.tryParse(_drinkCalCtrl.text.trim()) ?? 0;
    final total = s + m + side + d + dr;
    if (total > 0) {
      _caloriesCtrl.text = total.toString();
    }
  }

  void _saveMenu() {
    final pdks = context.read<PdksState>();
    final sCal = int.tryParse(_soupCalCtrl.text.trim()) ?? 160;
    final mCal = int.tryParse(_mainDishCalCtrl.text.trim()) ?? 380;
    final sideCal = int.tryParse(_sideDishCalCtrl.text.trim()) ?? 210;
    final desCal = int.tryParse(_dessertCalCtrl.text.trim()) ?? 190;
    final drCal = int.tryParse(_drinkCalCtrl.text.trim()) ?? 80;
    final vCal = int.tryParse(_vegCalCtrl.text.trim()) ?? 260;
    final totalCal = int.tryParse(_caloriesCtrl.text.trim()) ?? (sCal + mCal + sideCal + desCal + drCal);

    final updated = CafeteriaMenu(
      date: DateTime.now(),
      soup: _soupCtrl.text.trim().isEmpty ? 'Süzme Mercimek Çorbası' : _soupCtrl.text.trim(),
      soupCalories: sCal,
      mainDish: _mainDishCtrl.text.trim().isEmpty ? 'Hasanpaşa Köfte' : _mainDishCtrl.text.trim(),
      mainDishCalories: mCal,
      sideDish: _sideDishCtrl.text.trim().isEmpty ? 'Tereyağlı Pirinç Pilavı' : _sideDishCtrl.text.trim(),
      sideDishCalories: sideCal,
      dessertOrSalad: _dessertCtrl.text.trim().isEmpty ? 'Mevsim Salata & Kazandibi' : _dessertCtrl.text.trim(),
      dessertCalories: desCal,
      drink: _drinkCtrl.text.trim().isEmpty ? 'Ayran / Su' : _drinkCtrl.text.trim(),
      drinkCalories: drCal,
      totalCalories: totalCal,
      vegetarianAlternative: _vegCtrl.text.trim().isEmpty ? null : _vegCtrl.text.trim(),
      vegetarianCalories: vCal,
      chefNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      updatedBy: pdks.currentUser.fullName,
    );

    pdks.updateTodayMenu(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Text('Günün yemekhane menüsü ve kalorileri kaydedildi! 🍽️'),
      ),
    );
  }

  void _applyTemplate(
    String soup,
    int soupCal,
    String mainDish,
    int mainCal,
    String side,
    int sideCal,
    String dessert,
    int desCal,
    String veg,
    int vegCal,
    int drCal,
  ) {
    setState(() {
      _soupCtrl.text = soup;
      _soupCalCtrl.text = soupCal.toString();
      _mainDishCtrl.text = mainDish;
      _mainDishCalCtrl.text = mainCal.toString();
      _sideDishCtrl.text = side;
      _sideDishCalCtrl.text = sideCal.toString();
      _dessertCtrl.text = dessert;
      _dessertCalCtrl.text = desCal.toString();
      _vegCtrl.text = veg;
      _vegCalCtrl.text = vegCal.toString();
      _drinkCalCtrl.text = drCal.toString();
      _caloriesCtrl.text = (soupCal + mainCal + sideCal + desCal + drCal).toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('"$mainDish" şablonu ve kalorileri yüklendi.'),
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
            // Sadece Admin Rolünde Gözüken Canlı Düzenleme Çubuğu
            const AdminEditModeBar(
              pageId: 'cafeteria_shell',
              pageTitle: 'Mutfak Şefi & Yemekhane Yönetimi',
              editableSections: [
                PageSectionItem(id: 'counter_card', title: 'Yemekhane Sayaç Kartı'),
                PageSectionItem(id: 'two_week_banner', title: '2 Haftalık Çizelge Bannerı'),
              ],
            ),

            // Canlı Yemekhane Sayaç Kartı
            AdminEditableSection(
              pageId: 'cafeteria_shell',
              sectionId: 'counter_card',
              sectionTitle: 'Yemekhane Sayaç Kartı',
              child: Container(
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
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
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
            ),

            const SizedBox(height: 20),

            // 2 Haftalık Menü Yayınlama Kartı
            AdminEditableSection(
              pageId: 'cafeteria_shell',
              sectionId: 'two_week_banner',
              sectionTitle: '2 Haftalık Çizelge Bannerı',
              child: Container(
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
            ),

            const SizedBox(height: 24),

            // Şablon Menüler
            Text(
              'Hızlı Menü Şablonları & Kalorileri',
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
                    150,
                    'Hünkar Beğendi',
                    410,
                    'Pirinç Pilavı',
                    210,
                    'Fırın Sütlaç',
                    210,
                    'Zeytinyağlı Taze Fasulye',
                    220,
                    80,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Kebap Günü',
                    'Mercimek Çorbası',
                    160,
                    'Adana / Urfa Kebap',
                    450,
                    'Bulgur Pilavı & Köz',
                    190,
                    'Künefe / Baklava',
                    280,
                    'Mantar Sote',
                    220,
                    35,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'İtalyan Mutfağı',
                    'Domates Çorbası',
                    150,
                    'Fırın Tavuk Parmigiana',
                    380,
                    'Fettuccine Alfredo',
                    230,
                    'Tiramisu',
                    220,
                    'Sebzeli Lazanya',
                    260,
                    80,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Hafif & Akdeniz',
                    'Köz Patlıcan Çorbası',
                    130,
                    'Fırında Somon / Levrek',
                    350,
                    'Kinoa & Yeşillik',
                    130,
                    'Meyve Salatası',
                    120,
                    'Zeytinyağlı Enginar',
                    190,
                    35,
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
                              'Günün Menüsünü & Kalorilerini Belirle',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Yemek isimlerinin yanında kalori kutucukları bulunur',
                              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. Çorba + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'Günün Çorbası',
                    hint: 'Örn: Süzme Mercimek Çorbası, Ezogelin',
                    nameCtrl: _soupCtrl,
                    calCtrl: _soupCalCtrl,
                    icon: Icons.soup_kitchen_rounded,
                    color: const Color(0xFFF59E0B),
                    defaultCal: '160',
                  ),
                  const SizedBox(height: 14),

                  // 2. Ana Yemek + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'Ana Yemek',
                    hint: 'Örn: Hasanpaşa Köfte, Orman Kebabı, Fırın Tavuk',
                    nameCtrl: _mainDishCtrl,
                    calCtrl: _mainDishCalCtrl,
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEF4444),
                    defaultCal: '380',
                  ),
                  const SizedBox(height: 14),

                  // 3. Yan Yemek / Garnitür + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'Yan Yemek / Pilav / Makarna',
                    hint: 'Örn: Tereyağlı Pirinç Pilavı, Soslu Spagetti',
                    nameCtrl: _sideDishCtrl,
                    calCtrl: _sideDishCalCtrl,
                    icon: Icons.rice_bowl_rounded,
                    color: const Color(0xFF10B981),
                    defaultCal: '210',
                  ),
                  const SizedBox(height: 14),

                  // 4. Tatlı / Meyve / Salata + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'Tatlı / Meyve / Salata',
                    hint: 'Örn: Kazandibi, Mevsim Salata, Elma',
                    nameCtrl: _dessertCtrl,
                    calCtrl: _dessertCalCtrl,
                    icon: Icons.icecream_rounded,
                    color: const Color(0xFFEC4899),
                    defaultCal: '190',
                  ),
                  const SizedBox(height: 14),

                  // 5. İçecek + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'İçecek',
                    hint: 'Ayran / Su, Şalgam, Komposto',
                    nameCtrl: _drinkCtrl,
                    calCtrl: _drinkCalCtrl,
                    icon: Icons.local_drink_rounded,
                    color: const Color(0xFF0284C7),
                    defaultCal: '80',
                  ),
                  const SizedBox(height: 14),

                  // 6. Vejetaryen Alternatif + Kalori
                  _buildMenuInputFieldWithCalorie(
                    label: 'Vejetaryen Alternatif (Opsiyonel)',
                    hint: 'Örn: Zeytinyağlı Enginar & Fırın Sebze',
                    nameCtrl: _vegCtrl,
                    calCtrl: _vegCalCtrl,
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF10B981),
                    defaultCal: '260',
                  ),
                  const SizedBox(height: 16),

                  // Günlük Toplam Kalori Alanı (Hesaplanan ve elle değiştirilebilen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Günlük Toplam Kalori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Yemeklerin kalorileri değiştikçe otomatik toplanır', style: TextStyle(fontSize: 10.5, color: AppColors.textSub(context))),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _caloriesCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEA580C), fontSize: 14),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              suffixText: 'kcal',
                              suffixStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                              filled: true,
                              fillColor: AppColors.cardBg(context),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEA580C))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFFEA580C).withOpacity(0.4))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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

  Widget _buildMenuInputFieldWithCalorie({
    required String label,
    required String hint,
    required TextEditingController nameCtrl,
    required TextEditingController calCtrl,
    required IconData icon,
    required Color color,
    required String defaultCal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const Spacer(),
            Text('Kalori', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub(context))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Yemek Adı
            Expanded(
              flex: 7,
              child: TextField(
                controller: nameCtrl,
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
            ),
            const SizedBox(width: 8),
            // Kalori Kutusu
            Expanded(
              flex: 3,
              child: TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => _calculateTotalCalories(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: defaultCal,
                  suffixText: 'kcal',
                  suffixStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
                  prefixIcon: const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEA580C)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 0),
                  filled: true,
                  fillColor: AppColors.inputBg(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildTemplateChip(
    String title,
    String soup,
    int soupCal,
    String mainDish,
    int mainCal,
    String side,
    int sideCal,
    String dessert,
    int desCal,
    String veg,
    int vegCal,
    int drCal,
  ) {
    return ActionChip(
      avatar: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFEA580C)),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: () => _applyTemplate(soup, soupCal, mainDish, mainCal, side, sideCal, dessert, desCal, veg, vegCal, drCal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.cardBg(context),
      side: BorderSide(color: AppColors.cardBorder(context)),
    );
  }
}
