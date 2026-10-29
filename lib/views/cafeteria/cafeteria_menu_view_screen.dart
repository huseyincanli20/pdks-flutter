import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/platform_file_helper.dart';
import '../../models/cafeteria_menu.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import 'cafeteria_shell.dart';
import 'two_week_menu_publisher_screen.dart';

class CafeteriaMenuViewScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Günün Menüsü, 1: 14 Günlük Menü Çizelgesi
  const CafeteriaMenuViewScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CafeteriaMenuViewScreen> createState() => _CafeteriaMenuViewScreenState();
}

class _CafeteriaMenuViewScreenState extends State<CafeteriaMenuViewScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _weekTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _weekTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _weekTabController.dispose();
    super.dispose();
  }

  Future<void> _exportTwoWeekMenu(List<CafeteriaMenu> menus) async {
    final buffer = StringBuffer();
    buffer.writeln('========================================================');
    buffer.writeln('          2 HAFTALIK KURUMSAL YEMEK MENÜSÜ ÇİZELGESİ    ');
    buffer.writeln('========================================================\n');

    for (int w = 0; w < 2; w++) {
      buffer.writeln('--------------------------------------------------------');
      buffer.writeln('  ${w + 1}. HAFTA YEMEK PROGRAMI');
      buffer.writeln('--------------------------------------------------------');

      for (int d = 0; d < 7; d++) {
        final idx = (w * 7) + d;
        if (idx < menus.length) {
          final m = menus[idx];
          final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(m.date);
          buffer.writeln('\n[Gün ${idx + 1}] $dateStr');
          if (m.isCompleted) {
            buffer.writeln('  • Çorba: ${m.soup} (${m.soupCalories} kcal)');
            buffer.writeln('  • Ana Yemek: ${m.mainDish} (${m.mainDishCalories} kcal)');
            buffer.writeln('  • Yan Yemek: ${m.sideDish} (${m.sideDishCalories} kcal)');
            buffer.writeln('  • Tatlı / Salata: ${m.dessertOrSalad} (${m.dessertCalories} kcal)');
            buffer.writeln('  • İçecek: ${m.drink} (${m.drinkCalories} kcal)');
            buffer.writeln('  • Toplam Enerji: ~${m.totalCalories} kcal');
            if (m.vegetarianAlternative != null && m.vegetarianAlternative!.isNotEmpty) {
              buffer.writeln('  • Vejetaryen: ${m.vegetarianAlternative} (${m.vegetarianCalories} kcal)');
            }
            if (m.chefNote != null && m.chefNote!.isNotEmpty) {
              buffer.writeln('  • Şef Notu: ${m.chefNote}');
            }
          } else {
            buffer.writeln('  (Menü henüz girilmedi)');
          }
        }
      }
      buffer.writeln('\n');
    }

    final fileName = '2_Haftalik_Yemekhane_Menusu_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    await PlatformFileHelper.saveAndOpen(
      fileName: fileName,
      content: buffer.toString(),
      mimeType: 'text/plain;charset=utf-8',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileName başarıyla indirildi.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final menu = pdks.todayMenu;
    final twoWeekMenus = pdks.twoWeekMenus;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = pdks.currentUser;
    final canManageMenu = user.role == UserRole.cafeteria ||
        user.role == UserRole.hr ||
        user.role == UserRole.boss ||
        user.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Yemekhane Menüsü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.cardBg(context),
            child: TabBar(
              controller: _mainTabController,
              indicatorColor: const Color(0xFFEA580C),
              labelColor: const Color(0xFFEA580C),
              unselectedLabelColor: AppColors.textSub(context),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Günün Menüsü', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('2 Haftalık Çizelge', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (canManageMenu)
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
          if (canManageMenu)
            IconButton(
              icon: const Icon(Icons.soup_kitchen_rounded),
              tooltip: 'Günün Menüsünü Düzenle',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaShell()));
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // 1. SEKME: Günün Menüsü
          _buildTodayMenuView(context, menu, isDark),

          // 2. SEKME: 2 Haftalık Menü Çizelgesi (14 Gün)
          _buildTwoWeekScheduleView(context, twoWeekMenus, isDark, canManageMenu),
        ],
      ),
    );
  }

  // ===================== GÜNÜN MENÜSÜ GÖRÜNÜMÜ =====================
  Widget _buildTodayMenuView(BuildContext context, CafeteriaMenu menu, bool isDark) {
    return SingleChildScrollView(
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
            name: menu.soup.isEmpty ? 'Belirtilmedi' : menu.soup,
            icon: Icons.soup_kitchen_outlined,
            color: const Color(0xFFF59E0B),
            calorieHint: '${menu.soupCalories} kcal',
          ),
          const SizedBox(height: 10),

          // 2. Ana Yemek
          _buildMenuItemCard(
            context: context,
            category: 'ANA YEMEK',
            name: menu.mainDish.isEmpty ? 'Belirtilmedi' : menu.mainDish,
            icon: Icons.restaurant_rounded,
            color: const Color(0xFFEF4444),
            calorieHint: '${menu.mainDishCalories} kcal',
          ),
          const SizedBox(height: 10),

          // 3. Yan Yemek / Pilav / Makarna
          _buildMenuItemCard(
            context: context,
            category: 'YAN YEMEK / GARNİTÜR',
            name: menu.sideDish.isEmpty ? 'Belirtilmedi' : menu.sideDish,
            icon: Icons.rice_bowl_outlined,
            color: const Color(0xFF10B981),
            calorieHint: '${menu.sideDishCalories} kcal',
          ),
          const SizedBox(height: 10),

          // 4. Tatlı / Meyve / Salata
          _buildMenuItemCard(
            context: context,
            category: 'TATLI / MEYVE / SALATA',
            name: menu.dessertOrSalad.isEmpty ? 'Belirtilmedi' : menu.dessertOrSalad,
            icon: Icons.icecream_outlined,
            color: const Color(0xFFEC4899),
            calorieHint: '${menu.dessertCalories} kcal',
          ),
          const SizedBox(height: 10),

          // 5. İçecek
          _buildMenuItemCard(
            context: context,
            category: 'İÇECEK',
            name: menu.drink.isEmpty ? 'Ayran / Su' : menu.drink,
            icon: Icons.local_drink_outlined,
            color: const Color(0xFF0284C7),
            calorieHint: '${menu.drinkCalories} kcal',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${menu.vegetarianCalories} kcal',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
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
    );
  }

  // ===================== 2 HAFTALIK ÇİZELGE GÖRÜNÜMÜ =====================
  Widget _buildTwoWeekScheduleView(
    BuildContext context,
    List<CafeteriaMenu> menus,
    bool isDark,
    bool canManageMenu,
  ) {
    if (menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Henüz 2 haftalık menü yayınlanmamış.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (canManageMenu)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Menü Şablonu Yayınla'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoWeekMenuPublisherScreen()));
                },
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Üst Bilgi ve Hafta Seçici Bar
        Container(
          color: AppColors.cardBg(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _weekTabController,
                    indicatorColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSub(context),
                    tabs: const [
                      Tab(text: '1. Hafta (Gün 1-7)'),
                      Tab(text: '2. Hafta (Gün 8-14)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Color(0xFFEA580C)),
                tooltip: 'Çizelgeyi İndir (TXT)',
                onPressed: () => _exportTwoWeekMenu(menus),
              ),
              if (canManageMenu)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFEA580C)),
                  tooltip: 'Menüleri Düzenle',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoWeekMenuPublisherScreen()));
                  },
                ),
            ],
          ),
        ),

        // 14 Günlük Liste (Hafta 1 & Hafta 2)
        Expanded(
          child: TabBarView(
            controller: _weekTabController,
            children: [
              _buildWeekCardsList(context, menus.sublist(0, menus.length >= 7 ? 7 : menus.length), 1, isDark),
              _buildWeekCardsList(
                context,
                menus.length > 7 ? menus.sublist(7, menus.length >= 14 ? 14 : menus.length) : [],
                2,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCardsList(BuildContext context, List<CafeteriaMenu> weekMenus, int weekNumber, bool isDark) {
    if (weekMenus.isEmpty) {
      return const Center(child: Text('Bu hafta için menü bulunmuyor.'));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
      itemCount: weekMenus.length,
      itemBuilder: (context, index) {
        final m = weekMenus[index];
        final isToday = m.isSameDay(DateTime.now());
        final dayName = DateFormat('EEEE', 'tr_TR').format(m.date);
        final dateFormatted = DateFormat('d MMMM yyyy', 'tr_TR').format(m.date);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday ? const Color(0xFFEA580C) : AppColors.cardBorder(context),
              width: isToday ? 2 : 1,
            ),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kart Başlığı (Tarih + Bugün Rozeti + Kalori)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFFEA580C).withOpacity(isDark ? 0.25 : 0.1)
                      : AppColors.inputBg(context).withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: isToday ? const Color(0xFFEA580C) : AppColors.text(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $dateFormatted',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSub(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isToday) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BUGÜN',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${m.totalCalories} kcal',
                            style: const TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Yemek Kalemleri
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCompactMealRow(Icons.soup_kitchen_rounded, 'Çorba', m.soup, m.soupCalories, const Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
                    _buildCompactMealRow(Icons.restaurant_rounded, 'Ana Yemek', m.mainDish, m.mainDishCalories, const Color(0xFFEF4444), isMain: true),
                    const SizedBox(height: 8),
                    _buildCompactMealRow(Icons.rice_bowl_rounded, 'Yan Yemek', m.sideDish, m.sideDishCalories, const Color(0xFF10B981)),
                    const SizedBox(height: 8),
                    _buildCompactMealRow(Icons.icecream_rounded, 'Tatlı/Salata', m.dessertOrSalad, m.dessertCalories, const Color(0xFFEC4899)),
                    const SizedBox(height: 8),
                    _buildCompactMealRow(Icons.local_drink_rounded, 'İçecek', m.drink, m.drinkCalories, const Color(0xFF0284C7)),

                    // Vejetaryen Alternatif Varsa
                    if (m.vegetarianAlternative != null && m.vegetarianAlternative!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Vejetaryen: ${m.vegetarianAlternative!}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${m.vegetarianCalories} kcal',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Şef Notu Varsa
                    if (m.chefNote != null && m.chefNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m.chefNote!,
                              style: TextStyle(color: AppColors.textSub(context), fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactMealRow(
    IconData icon,
    String label,
    String value,
    int calories,
    Color color, {
    bool isMain = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textSub(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: isMain ? 13.5 : 12.5,
              fontWeight: isMain ? FontWeight.w800 : FontWeight.w600,
              color: isMain ? AppColors.text(context) : AppColors.text(context).withOpacity(0.9),
            ),
          ),
        ),
        if (value.isNotEmpty && calories > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(
              '$calories kcal',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ],
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
