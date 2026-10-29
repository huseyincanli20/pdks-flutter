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

  // Form Controllers (Yemek İsimleri & Bireysel Kalorileri)
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

  late TextEditingController _vegCtrl;
  late TextEditingController _vegCalCtrl;

  late TextEditingController _caloriesCtrl; // Toplam Kalori
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
    _soupCalCtrl = TextEditingController();

    _mainDishCtrl = TextEditingController();
    _mainDishCalCtrl = TextEditingController();

    _sideDishCtrl = TextEditingController();
    _sideDishCalCtrl = TextEditingController();

    _dessertCtrl = TextEditingController();
    _dessertCalCtrl = TextEditingController();

    _drinkCtrl = TextEditingController();
    _drinkCalCtrl = TextEditingController();

    _vegCtrl = TextEditingController();
    _vegCalCtrl = TextEditingController();

    _caloriesCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    _loadDayIntoControllers(_selectedDayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    _vegCtrl.dispose();
    _vegCalCtrl.dispose();
    _caloriesCtrl.dispose();
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

  void _loadDayIntoControllers(int index) {
    final m = _editableMenus[index];
    _soupCtrl.text = m.soup;
    _soupCalCtrl.text = m.soupCalories > 0 ? m.soupCalories.toString() : '160';

    _mainDishCtrl.text = m.mainDish;
    _mainDishCalCtrl.text = m.mainDishCalories > 0 ? m.mainDishCalories.toString() : '380';

    _sideDishCtrl.text = m.sideDish;
    _sideDishCalCtrl.text = m.sideDishCalories > 0 ? m.sideDishCalories.toString() : '210';

    _dessertCtrl.text = m.dessertOrSalad;
    _dessertCalCtrl.text = m.dessertCalories > 0 ? m.dessertCalories.toString() : '190';

    _drinkCtrl.text = m.drink;
    _drinkCalCtrl.text = m.drinkCalories > 0 ? m.drinkCalories.toString() : '80';

    _vegCtrl.text = m.vegetarianAlternative ?? '';
    _vegCalCtrl.text = m.vegetarianCalories > 0 ? m.vegetarianCalories.toString() : '260';

    _caloriesCtrl.text = m.totalCalories > 0 ? m.totalCalories.toString() : m.calculatedTotalCalories.toString();
    _noteCtrl.text = m.chefNote ?? '';
  }

  void _saveCurrentControllersToDay() {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _editableMenus.length) return;
    final current = _editableMenus[_selectedDayIndex];

    final sCal = int.tryParse(_soupCalCtrl.text.trim()) ?? current.soupCalories;
    final mCal = int.tryParse(_mainDishCalCtrl.text.trim()) ?? current.mainDishCalories;
    final sideCal = int.tryParse(_sideDishCalCtrl.text.trim()) ?? current.sideDishCalories;
    final desCal = int.tryParse(_dessertCalCtrl.text.trim()) ?? current.dessertCalories;
    final drCal = int.tryParse(_drinkCalCtrl.text.trim()) ?? current.drinkCalories;
    final vCal = int.tryParse(_vegCalCtrl.text.trim()) ?? current.vegetarianCalories;
    final total = int.tryParse(_caloriesCtrl.text.trim()) ?? (sCal + mCal + sideCal + desCal + drCal);

    _editableMenus[_selectedDayIndex] = current.copyWith(
      soup: _soupCtrl.text.trim(),
      soupCalories: sCal,
      mainDish: _mainDishCtrl.text.trim(),
      mainDishCalories: mCal,
      sideDish: _sideDishCtrl.text.trim(),
      sideDishCalories: sideCal,
      dessertOrSalad: _dessertCtrl.text.trim(),
      dessertCalories: desCal,
      drink: _drinkCtrl.text.trim().isEmpty ? 'Ayran / Su' : _drinkCtrl.text.trim(),
      drinkCalories: drCal,
      totalCalories: total,
      vegetarianAlternative: _vegCtrl.text.trim().isEmpty ? null : _vegCtrl.text.trim(),
      vegetarianCalories: vCal,
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
    required int soupCal,
    required String main,
    required int mainCal,
    required String side,
    required int sideCal,
    required String dessert,
    required int desCal,
    required String veg,
    required int vegCal,
    required int drinkCal,
  }) {
    setState(() {
      _soupCtrl.text = soup;
      _soupCalCtrl.text = soupCal.toString();

      _mainDishCtrl.text = main;
      _mainDishCalCtrl.text = mainCal.toString();

      _sideDishCtrl.text = side;
      _sideDishCalCtrl.text = sideCal.toString();

      _dessertCtrl.text = dessert;
      _dessertCalCtrl.text = desCal.toString();

      _vegCtrl.text = veg;
      _vegCalCtrl.text = vegCal.toString();

      _drinkCalCtrl.text = drinkCal.toString();
      _caloriesCtrl.text = (soupCal + mainCal + sideCal + desCal + drinkCal).toString();

      _saveCurrentControllersToDay();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seçilen güne "$main" menüsü ve kalorileri yüklendi.'),
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
          '14 günün tamamı zengin yemekler ve her yemeğin ayrı ayrı kalorileriyle '
          'otomatik olarak doldurulacaktır. Mevcut düzenlemelerinizin üzerine yazılacaktır. Onaylıyor musunuz?',
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
                  content: Text('14 günlük hazır yemekhane menüsü ve kalorileri yüklendi! 🍲'),
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
                    soupCalories: 0,
                    mainDish: '',
                    mainDishCalories: 0,
                    sideDish: '',
                    sideDishCalories: 0,
                    dessertOrSalad: '',
                    dessertCalories: 0,
                    drink: 'Ayran / Su',
                    drinkCalories: 0,
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
          '14 günlük yemek menüsü ve yemek bazlı kalori bilgileri sisteme kaydedildi. '
          'Tüm şirket çalışanlarına mobil bildirim gönderildi.\n\n'
          '• Toplam Dolu Gün: $filledDaysCount / 14\n'
          '• Her yemeğin kalori değeri personele gösterilmektedir.',
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
                MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen(initialTabIndex: 1)),
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
    buffer.writeln('     2 HAFTALIK KURUMSAL YEMEK MENÜSÜ & KALORİ ÇİZELGESİ  ');
    buffer.writeln('========================================================\n');

    for (int w = 0; w < 2; w++) {
      buffer.writeln('--------------------------------------------------------');
      buffer.writeln('  ${w + 1}. HAFTA YEMEK VE BESİN DEĞERLERİ PROGRAMI');
      buffer.writeln('--------------------------------------------------------');

      for (int d = 0; d < 7; d++) {
        final idx = (w * 7) + d;
        final m = _editableMenus[idx];
        final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(m.date);
        buffer.writeln('\n[Gün ${idx + 1}] $dateStr');
        if (m.isCompleted) {
          buffer.writeln('  • Çorba: ${m.soup} (${m.soupCalories} kcal)');
          buffer.writeln('  • Ana Yemek: ${m.mainDish} (${m.mainDishCalories} kcal)');
          buffer.writeln('  • Yan Yemek: ${m.sideDish} (${m.sideDishCalories} kcal)');
          buffer.writeln('  • Tatlı / Salata: ${m.dessertOrSalad} (${m.dessertCalories} kcal)');
          buffer.writeln('  • İçecek: ${m.drink} (${m.drinkCalories} kcal)');
          buffer.writeln('  • Günlük Toplam Enerji: ~${m.totalCalories} kcal');
          if (m.vegetarianAlternative != null && m.vegetarianAlternative!.isNotEmpty) {
            buffer.writeln('  • Vejetaryen Alternatif: ${m.vegetarianAlternative} (${m.vegetarianCalories} kcal)');
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
          content: Text('$fileName başarıyla indirildi.'),
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
            Text('14 Günlük Yemek & Kalori Yönetimi', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuViewScreen(initialTabIndex: 1)));
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

                  // Menü Formu (Her Yemeğin Yanında Kalori Yeri)
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
                        // Bilgilendirme Başlığı
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFEA580C)),
                            const SizedBox(width: 6),
                            Text(
                              'Yemek Listesi & Kalori Değerleri',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Her yemeğin yanındaki kutucuğa porsiyon kalorisini girebilirsiniz.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                        ),
                        const SizedBox(height: 16),

                        // 1. Çorba + Kalori
                        _buildMealWithCalorieRow(
                          label: 'Günün Çorbası',
                          hint: 'Örn: Süzme Mercimek, Ezogelin, Yayla',
                          nameCtrl: _soupCtrl,
                          calCtrl: _soupCalCtrl,
                          icon: Icons.soup_kitchen_rounded,
                          accentColor: const Color(0xFFF59E0B),
                          defaultCal: '160',
                        ),
                        const SizedBox(height: 14),

                        // 2. Ana Yemek + Kalori
                        _buildMealWithCalorieRow(
                          label: 'Ana Yemek',
                          hint: 'Örn: Hasanpaşa Köfte, Kuru Fasulye, Somon',
                          nameCtrl: _mainDishCtrl,
                          calCtrl: _mainDishCalCtrl,
                          icon: Icons.restaurant_rounded,
                          accentColor: const Color(0xFFEF4444),
                          defaultCal: '380',
                        ),
                        const SizedBox(height: 14),

                        // 3. Yan Yemek + Kalori
                        _buildMealWithCalorieRow(
                          label: 'Yan Yemek / Pilav / Makarna',
                          hint: 'Örn: Tereyağlı Pirinç Pilavı, Makarna',
                          nameCtrl: _sideDishCtrl,
                          calCtrl: _sideDishCalCtrl,
                          icon: Icons.rice_bowl_rounded,
                          accentColor: const Color(0xFF10B981),
                          defaultCal: '210',
                        ),
                        const SizedBox(height: 14),

                        // 4. Tatlı / Meyve / Salata + Kalori
                        _buildMealWithCalorieRow(
                          label: 'Tatlı / Salata / Meyve',
                          hint: 'Örn: Mevsim Salata, Fırın Sütlaç, Kazandibi',
                          nameCtrl: _dessertCtrl,
                          calCtrl: _dessertCalCtrl,
                          icon: Icons.icecream_rounded,
                          accentColor: const Color(0xFFEC4899),
                          defaultCal: '190',
                        ),
                        const SizedBox(height: 14),

                        // 5. İçecek + Kalori
                        _buildMealWithCalorieRow(
                          label: 'İçecek',
                          hint: 'Ayran / Su, Şalgam, Komposto',
                          nameCtrl: _drinkCtrl,
                          calCtrl: _drinkCalCtrl,
                          icon: Icons.local_drink_rounded,
                          accentColor: const Color(0xFF0284C7),
                          defaultCal: '80',
                        ),
                        const SizedBox(height: 14),

                        // 6. Vejetaryen Alternatif + Kalori
                        _buildMealWithCalorieRow(
                          label: 'Vejetaryen Alternatif (Opsiyonel)',
                          hint: 'Örn: Zeytinyağlı Enginar, Sebze Güveç',
                          nameCtrl: _vegCtrl,
                          calCtrl: _vegCalCtrl,
                          icon: Icons.eco_rounded,
                          accentColor: const Color(0xFF10B981),
                          defaultCal: '260',
                        ),
                        const SizedBox(height: 16),

                        // Toplam Günlük Kalori Göstergesi / Düzenleyicisi
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
                                    Text('Yemeklerin toplamı otomatik hesaplanır', style: TextStyle(fontSize: 10.5, color: AppColors.textSub(context))),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _caloriesCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => _saveCurrentControllersToDay(),
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
                      child: const Text(
                        'BUGÜN',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
              'Güne Hızlı Şablon & Kaloriler',
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
              _buildQuickTemplateChip('🍖 Geleneksel Köfte', 'Süzme Mercimek', 160, 'Hasanpaşa Köfte', 380, 'Tereyağlı Pirinç Pilavı', 210, 'Fırın Sütlaç', 210, 'Zeytinyağlı Enginar', 260, 80),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🍗 Fırın Tavuk', 'Tarhana Çorbası', 150, 'Fırın Tavuk Baget', 360, 'Patates Püresi', 190, 'Mozaik Pasta', 210, 'Mantar Sote', 220, 90),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🍲 Kuru Fasulye', 'Ezogelin Çorbası', 150, 'Kuru Fasulye', 410, 'Pirinç Pilavı', 210, 'Cacık & Revani', 240, 'Barbunya Pilaki', 280, 80),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🐟 Fırın Somon', 'Köz Patlıcan', 130, 'Fırında Somon Balığı', 350, 'Buharda Sebze', 120, 'İrmik Helvası', 240, 'Karnabahar Steak', 190, 35),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🥟 Ev Mantısı', 'Yayla Çorbası', 140, 'Kayseri Mantısı (Yoğurtlu)', 440, 'Salata', 110, 'Trileçe', 230, 'Ispanaklı Mantı', 320, 80),
              const SizedBox(width: 8),
              _buildQuickTemplateChip('🥩 Dana Rosto', 'Brokoli Çorbası', 130, 'Dana Rosto & Sos', 380, 'Patates Püresi', 190, 'Profiterol', 240, 'Sebzeli Noodle', 280, 90),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTemplateChip(
    String label,
    String soup,
    int soupCal,
    String main,
    int mainCal,
    String side,
    int sideCal,
    String dessert,
    int desCal,
    String veg,
    int vegCal,
    int drinkCal,
  ) {
    return ActionChip(
      avatar: const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFEA580C)),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.cardBg(context),
      side: BorderSide(color: AppColors.cardBorder(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () => _applyQuickTemplateForDay(
        soup: soup,
        soupCal: soupCal,
        main: main,
        mainCal: mainCal,
        side: side,
        sideCal: sideCal,
        dessert: dessert,
        desCal: desCal,
        veg: veg,
        vegCal: vegCal,
        drinkCal: drinkCal,
      ),
    );
  }

  Widget _buildMealWithCalorieRow({
    required String label,
    required String hint,
    required TextEditingController nameCtrl,
    required TextEditingController calCtrl,
    required IconData icon,
    required Color accentColor,
    required String defaultCal,
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
            const Spacer(),
            Text(
              'Kalori Değeri',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub(context)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Yemek Adı Giriş Alanı
            Expanded(
              flex: 7,
              child: TextField(
                controller: nameCtrl,
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
            ),
            const SizedBox(width: 8),
            // Kalori Değeri Giriş Alanı
            Expanded(
              flex: 3,
              child: TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) {
                  _calculateTotalCalories();
                  _saveCurrentControllersToDay();
                },
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: defaultCal,
                  suffixText: 'kcal',
                  suffixStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSub(context)),
                  prefixIcon: const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEA580C)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 0),
                  filled: true,
                  fillColor: AppColors.inputBg(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color accentColor,
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
