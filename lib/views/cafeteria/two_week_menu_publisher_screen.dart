import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/platform_file_helper.dart';
import '../../models/cafeteria_menu.dart';
import '../../state/pdks_state.dart';
import 'cafeteria_menu_view_screen.dart';

class TwoWeekMenuPublisherScreen extends StatefulWidget {
  const TwoWeekMenuPublisherScreen({super.key});

  @override
  State<TwoWeekMenuPublisherScreen> createState() => _TwoWeekMenuPublisherScreenState();
}

class _TwoWeekMenuPublisherScreenState extends State<TwoWeekMenuPublisherScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<CafeteriaMenu> _editableMenus;
  int _selectedDayIndex = 0; // 0 to 13

  // Form Controllers
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final targetWeekStart = _tabController.index * 7;
        if (_selectedDayIndex < targetWeekStart || _selectedDayIndex >= targetWeekStart + 7) {
          _selectDay(targetWeekStart);
        }
      }
    });

    final pdks = context.read<PdksState>();
    if (pdks.twoWeekMenus.isNotEmpty && pdks.twoWeekMenus.length == 14) {
      _editableMenus = pdks.twoWeekMenus.map((m) => m.copyWith()).toList();
    } else {
      _editableMenus = PdksState.buildDefaultTwoWeekMenu();
    }

    // Bugünü otomatik seç
    final now = DateTime.now();
    int initialDay = _editableMenus.indexWhere((m) => m.isSameDay(now));
    if (initialDay != -1) {
      _selectedDayIndex = initialDay;
      if (initialDay >= 7) {
        _tabController.index = 1;
      }
    }

    _soupCtrl = TextEditingController();
    _mainDishCtrl = TextEditingController();
    _sideDishCtrl = TextEditingController();
    _dessertCtrl = TextEditingController();
    _drinkCtrl = TextEditingController();
    _caloriesCtrl = TextEditingController();
    _vegCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    _loadDayIntoControllers(_selectedDayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _loadDayIntoControllers(int index) {
    final m = _editableMenus[index];
    _soupCtrl.text = m.soup;
    _mainDishCtrl.text = m.mainDish;
    _sideDishCtrl.text = m.sideDish;
    _dessertCtrl.text = m.dessertOrSalad;
    _drinkCtrl.text = m.drink;
    _caloriesCtrl.text = m.totalCalories > 0 ? m.totalCalories.toString() : '';
    _vegCtrl.text = m.vegetarianAlternative ?? '';
    _noteCtrl.text = m.chefNote ?? '';
  }

  void _saveCurrentControllersToDay() {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _editableMenus.length) return;
    final current = _editableMenus[_selectedDayIndex];
    _editableMenus[_selectedDayIndex] = current.copyWith(
      soup: _soupCtrl.text.trim(),
      mainDish: _mainDishCtrl.text.trim(),
      sideDish: _sideDishCtrl.text.trim(),
      dessertOrSalad: _dessertCtrl.text.trim(),
      drink: _drinkCtrl.text.trim().isEmpty ? 'Ayran / Su' : _drinkCtrl.text.trim(),
      totalCalories: int.tryParse(_caloriesCtrl.text.trim()) ?? (current.totalCalories > 0 ? current.totalCalories : 800),
      vegetarianAlternative: _vegCtrl.text.trim().isEmpty ? null : _vegCtrl.text.trim(),
      chefNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  void _selectDay(int index) {
    if (index < 0 || index >= _editableMenus.length) return;
    _saveCurrentControllersToDay();
    setState(() {
      _selectedDayIndex = index;
      _loadDayIntoControllers(index);
      if (index >= 7 && _tabController.index != 1) {
        _tabController.animateTo(1);
      } else if (index < 7 && _tabController.index != 0) {
        _tabController.animateTo(0);
      }
    });
  }

  void _applyQuickTemplateForDay({
    required String soup,
    required String main,
    required String side,
    required String dessert,
    required String veg,
    required int cal,
  }) {
    setState(() {
      _soupCtrl.text = soup;
      _mainDishCtrl.text = main;
      _sideDishCtrl.text = side;
      _dessertCtrl.text = dessert;
      _vegCtrl.text = veg;
      _caloriesCtrl.text = cal.toString();
      _saveCurrentControllersToDay();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seçilen güne "$main" menüsü yüklendi.'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _populateAllWithDefaultTemplate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text('14 Günlük Şablonu Doldur'),
          ],
        ),
        content: const Text(
          '14 günün tamamı zengin ve dengeli kurumsal Türk mutfağı menüleriyle otomatik olarak doldurulacaktır. '
          'Mevcut düzenlemelerinizin üzerine yazılacaktır. Onaylıyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _editableMenus = PdksState.buildDefaultTwoWeekMenu();
                _loadDayIntoControllers(_selectedDayIndex);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('14 günlük hazır yemekhane menüsü yüklendi! 🍲'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Evet, Doldur'),
          ),
        ],
      ),
    );
  }

  void _clearAllMenus() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('14 Günü Sıfırla'),
          ],
        ),
        content: const Text('Tüm 14 günün menü girişleri temizlenecek ve boş taslak oluşturulacaktır. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final now = DateTime.now();
                final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                _editableMenus = List.generate(14, (i) {
                  return CafeteriaMenu(
                    date: monday.add(Duration(days: i)),
                    soup: '',
                    mainDish: '',
                    sideDish: '',
                    dessertOrSalad: '',
                    drink: 'Ayran / Su',
                    totalCalories: 0,
                  );
                });
                _loadDayIntoControllers(_selectedDayIndex);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm 14 günlük liste sıfırlandı.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _publishTwoWeekMenus() {
    _saveCurrentControllersToDay();

    // Dolu olan gün sayısını say
    final filledDaysCount = _editableMenus.where((m) => m.isCompleted).length;

    if (filledDaysCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yayınlamadan önce en az bir günün ana yemek ve çorba bilgisini doldurun.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pdks = context.read<PdksState>();
    pdks.setTwoWeekMenus(_editableMenus, publishNotification: true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('2 Haftalık Menü Yayınlandı!')),
          ],
        ),
        content: Text(
          '14 günlük yemek menüsü sisteme kaydedildi ve tüm şirket personeline '
          'mobil bildirim gönderildi.\n\n'
          '• Toplam Dolu Gün: $filledDaysCount / 14\n'
          '• Bugünün menüsü otomatik olarak güncellendi.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Düzenlemeye Devam Et'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Menü Çizelgesini Gör'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportTwoWeekMenu() async {
    _saveCurrentControllersToDay();
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
        final m = _editableMenus[idx];
        final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(m.date);
        buffer.writeln('\n[Gün ${idx + 1}] $dateStr');
        if (m.isCompleted) {
          buffer.writeln('  • Çorba: ${m.soup}');
          buffer.writeln('  • Ana Yemek: ${m.mainDish}');
          buffer.writeln('  • Yan Yemek: ${m.sideDish}');
          buffer.writeln('  • Tatlı / Salata: ${m.dessertOrSalad}');
          buffer.writeln('  • İçecek: ${m.drink}');
          buffer.writeln('  • Enerji Değeri: ~${m.totalCalories} kcal');
          if (m.vegetarianAlternative != null && m.vegetarianAlternative!.isNotEmpty) {
            buffer.writeln('  • Vejetaryen Alternatif: ${m.vegetarianAlternative}');
          }
          if (m.chefNote != null && m.chefNote!.isNotEmpty) {
            buffer.writeln('  • Not / Alerjen: ${m.chefNote}');
          }
        } else {
          buffer.writeln('  (Menü henüz girilmedi)');
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
          content: Text('$fileName başarıyla hazırlandı ve indirildi.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMenu = _editableMenus[_selectedDayIndex];
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(currentMenu.date);
    final isToday = currentMenu.isSameDay(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2 Haftalık Menü Yayınla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('14 Günlük Yemek Çizelgesi Planlama', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Metin / Çizelgeyi İndir',
            onPressed: _exportTwoWeekMenu,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'template') _populateAllWithDefaultTemplate();
              if (val == 'clear') _clearAllMenus();
              if (val == 'preview') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen()));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFEA580C), size: 18),
                    SizedBox(width: 8),
                    Text('14 Günlük Şablonu Doldur'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Menü Çizelgesini İncele'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Tüm 14 Günü Sıfırla'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Hafta Seçim Sekmesi (1. Hafta / 2. Hafta)
          Container(
            color: AppColors.cardBg(context),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFEA580C),
              labelColor: const Color(0xFFEA580C),
              unselectedLabelColor: AppColors.textSub(context),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.looks_one_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('1. Hafta (Gün 1-7)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.looks_two_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('2. Hafta (Gün 8-14)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Yatay Gün Seçici Şeridi (7 Günlük Karusel)
          _buildDaySelectorCarousel(),

          const Divider(height: 1),

          // Günlük Menü Düzenleme Alanı (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seçili Gün Başlığı ve Hızlı İşlemler
                  _buildSelectedDayHeader(dateStr, isToday),

                  const SizedBox(height: 14),

                  // Gün İçi Hızlı Şablonlar
                  _buildDayQuickTemplates(),

                  const SizedBox(height: 16),

                  // Menü Formu
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Çorba
                        _buildInputField(
                          label: 'Günün Çorbası',
                          hint: 'Örn: Süzme Mercimek, Ezogelin, Yayla Çorbası',
                          controller: _soupCtrl,
                          icon: Icons.soup_kitchen_rounded,
                          accentColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 14),

                        // Ana Yemek
                        _buildInputField(
                          label: 'Ana Yemek',
                          hint: 'Örn: Hasanpaşa Köfte, Kuru Fasulye, Fırın Somon',
                          controller: _mainDishCtrl,
                          icon: Icons.restaurant_rounded,
                          accentColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 14),

                        // Yan Yemek
                        _buildInputField(
                          label: 'Yan Yemek / Pilav / Makarna',
                          hint: 'Örn: Tereyağlı Pirinç Pilavı, Domatesli Makarna',
                          controller: _sideDishCtrl,
                          icon: Icons.rice_bowl_rounded,
                          accentColor: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 14),

                        // Tatlı / Meyve / Salata
                        _buildInputField(
                          label: 'Tatlı / Salata / Meyve',
                          hint: 'Örn: Mevsim Salata, Fırın Sütlaç, Kazandibi',
                          controller: _dessertCtrl,
                          icon: Icons.icecream_rounded,
                          accentColor: const Color(0xFFEC4899),
                        ),
                        const SizedBox(height: 14),

                        // İçecek & Kalori
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildInputField(
                                label: 'İçecek',
                                hint: 'Ayran / Su, Şalgam, Komposto',
                                controller: _drinkCtrl,
                                icon: Icons.local_drink_rounded,
                                accentColor: const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                label: 'Kalori (kcal)',
                                hint: '820',
                                controller: _caloriesCtrl,
                                icon: Icons.local_fire_department_rounded,
                                accentColor: const Color(0xFFEA580C),
                                isNumeric: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Vejetaryen Alternatif
                        _buildInputField(
                          label: 'Vejetaryen Alternatif (Opsiyonel)',
                          hint: 'Örn: Zeytinyağlı Enginar, Sebze Güveç, Mantar Sote',
                          controller: _vegCtrl,
                          icon: Icons.eco_rounded,
                          accentColor: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 14),

                        // Şefin Notu / Alerjen
                        _buildInputField(
                          label: 'Şefin Notu & Alerjen Bilgisi',
                          hint: 'Örn: Glüten ve laktoz içerir. Taze çiftlik ürünleri kullanılmıştır.',
                          controller: _noteCtrl,
                          icon: Icons.edit_note_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Günler Arası Gezinme Düğmeleri
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Önceki Gün'),
                          onPressed: _selectedDayIndex > 0
                              ? () => _selectDay(_selectedDayIndex - 1)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder(context)),
                        ),
                        child: Text(
                          '${_selectedDayIndex + 1} / 14',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Sonraki Gün'),
                          onPressed: _selectedDayIndex < 13
                              ? () => _selectDay(_selectedDayIndex + 1)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Alt Sabit Yayınlama Çubuğu
          _buildPublishStickyBar(),
        ],
      ),
    );
  }

  Widget _buildDaySelectorCarousel() {
    final startOffset = _tabController.index * 7;
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: AppColors.cardBg(context).withOpacity(0.5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final globalIndex = startOffset + i;
          final menu = _editableMenus[globalIndex];
          final isSelected = globalIndex == _selectedDayIndex;
          final isToday = menu.isSameDay(DateTime.now());
          final hasItems = menu.isCompleted;

          final dayName = DateFormat('EEE', 'tr_TR').format(menu.date);
          final dayNum = DateFormat('d MMM', 'tr_TR').format(menu.date);

          return GestureDetector(
            onTap: () => _selectDay(globalIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : isToday
                        ? const Color(0xFFEA580C).withOpacity(0.12)
                        : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEA580C)
                      : isToday
                          ? const Color(0xFFEA580C)
                          : AppColors.cardBorder(context),
                  width: isToday ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFFEA580C)
                                  : AppColors.textSub(context),
                        ),
                      ),
                      if (hasItems) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: isSelected ? Colors.white : const Color(0xFF10B981),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.text(context),
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.3) : const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BUGÜN',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayHeader(String dateStr, bool isToday) {
    final weekNumber = (_selectedDayIndex ~/ 7) + 1;
    final dayInWeek = (_selectedDayIndex % 7) + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [const Color(0xFFEA580C), const Color(0xFFC2410C)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$weekNumber. HAFTA • $dayInWeek. GÜN',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BUGÜN',
                style: TextStyle(color: Color(0xFFEA580C), fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayQuickTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Güne Hızlı Şablon Uygula',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
            ),
            InkWell(
              onTap: _populateAllWithDefaultTemplate,
              child: const Text(
                'Tüm 14 Günü Doldur',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickTemplateChip('🍖 Geleneksel Köfte', 'Süzme Mercimek', 'Hasanpaşa Köfte', 'Tereyağlı Pirinç Pilavı', 'Fırın Sütlaç', 'Zeytinyağlı Enginar', 820),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🍗 Fırın Tavuk', 'Tarhana Çorbası', 'Fırın Tavuk Baget', 'Patates Püresi', 'Mozaik Pasta', 'Mantar Sote', 780),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🍲 Kuru Fasulye', 'Ezogelin Çorbası', 'Kuru Fasulye & Turşu', 'Pirinç Pilavı', 'Cacık & Revani', 'Barbunya Pilaki', 850),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🐟 Fırın Somon', 'Köz Patlıcan', 'Fırında Somon Balığı', 'Roka Salatası', 'İrmik Helvası', 'Karnabahar Steak', 680),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🥟 Ev Mantısı', 'Yayla Çorbası', 'Kayseri Mantısı (Yoğurtlu)', 'Mevsim Salata', 'Trileçe', 'Ispanaklı Mantı', 890),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🥩 Dana Rosto', 'Brokoli Çorbası', 'Dana Rosto & Sos', 'Püre & Makarna', 'Profiterol', 'Sebzeli Noodle', 810),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTemplateChip(String label, String soup, String main, String side, String dessert, String veg, int cal) {
    return ActionChip(
      avatar: const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFEA580C)),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.cardBg(context),
      side: BorderSide(color: AppColors.cardBorder(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () => _applyQuickTemplateForDay(
        soup: soup,
        main: main,
        side: side,
        dessert: dessert,
        veg: veg,
        cal: cal,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color accentColor,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: (_) => _saveCurrentControllersToDay(),
          style: TextStyle(fontSize: 13, color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11.5, color: AppColors.textSub(context)),
            filled: true,
            fillColor: AppColors.inputBg(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishStickyBar() {
    final filledDaysCount = _editableMenus.where((m) => m.isCompleted).length;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.cardBorder(context))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: filledDaysCount == 14
                  ? const Color(0xFF10B981).withOpacity(0.12)
                  : const Color(0xFFEA580C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$filledDaysCount/14',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: filledDaysCount == 14 ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                  ),
                ),
                Text(
                  'Dolu Gün',
                  style: TextStyle(fontSize: 9, color: AppColors.textSub(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.campaign_rounded, size: 20),
              label: const Text(
                '2 Haftalık Menüyü Yayınla',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _publishTwoWeekMenus,
            ),
          ),
        ],
      ),
    );
  }
}
