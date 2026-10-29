import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_list_screen.dart';
import '../payroll/payroll_management_screen.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class BossShell extends StatefulWidget {
  const BossShell({super.key});

  @override
  State<BossShell> createState() => _BossShellState();
}

class _BossShellState extends State<BossShell> {
  int _currentIndex = 0;

  final List<String> _tabTitles = [
    'Yönetim Özeti',
    'Rol ve Yetki Yönetimi',
    'Personel Kadrosu',
  ];

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;

    final tabs = [
      _buildDashboardTab(context, pdks),
      _buildRoleManagementTab(context, pdks),
      _buildEmployeesTab(context, pdks),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patron Paneli • ${_tabTitles[_currentIndex]}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${user.fullName} • ${user.title}',
                style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.text(context)),
                if (context.watch<PdksState>().unreadChatCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: AppColors.primaryOf(context), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          context.watch<PdksState>().unreadChatCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Şirket İçi Mesajlar',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            },
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: AppColors.text(context)),
                if (pdks.unreadNotificationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          pdks.unreadNotificationsCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Bildirimler',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('CEO / Yönetim', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AdminEditModeBar(
            pageId: 'boss_shell',
            pageTitle: 'Patron & CEO Paneli',
            editableSections: [
              PageSectionItem(id: 'boss_tab_$_currentIndex', title: '${_tabTitles[_currentIndex]} Görünümü'),
            ],
          ),
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: 'Rol Yönetimi',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Personel',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: YÖNETİM & MALİYET ÖZETİ (DASHBOARD)
  // ==========================================
  Widget _buildDashboardTab(BuildContext context, PdksState pdks) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CEO Stratejik Karşılama Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                      'ŞİRKET ÇALIŞMA & MALİYET ÖZETİ',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Ekim 2026', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  pdks.employees.isNotEmpty
                      ? 'Genel Devamlılık Oranı: %${((pdks.presentEmployeesCount / pdks.employees.length) * 100).toStringAsFixed(1)}'
                      : 'Genel Devamlılık Oranı: %0.0',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam ${pdks.employees.length} personelden ${pdks.presentEmployeesCount}\'i şu an aktif mesaide.',
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Toplam Fazla Mesai', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          pdks.payrolls.isNotEmpty
                              ? '+${pdks.payrolls.fold<double>(0.0, (acc, p) => acc + p.overtimeHours).toStringAsFixed(1)} Saat'
                              : '0.0 Saat',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tahmini Mesai Maliyeti', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          pdks.payrolls.isNotEmpty
                              ? '₺${pdks.payrolls.fold<double>(0.0, (acc, p) => acc + p.overtimePay).toStringAsFixed(0)} TL'
                              : '₺0 TL',
                          style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bordro & Şirket Maaş Bütçesi Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık Bordro & Maaş Havuzu',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ekim 2026 • ${pdks.payrolls.length} Onaylı Bordro Kaydı',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PayrollManagementScreen()),
                    );
                  },
                  child: const Text('Bordrolar ›', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Anlık Durum Sayaçları
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Aktif İçeride',
                  value: pdks.presentEmployeesCount.toString(),
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'İzinli / Raporlu',
                  value: pdks.onLeaveEmployeesCount.toString(),
                  color: AppColors.warning,
                  icon: Icons.beach_access,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Geç Kalan',
                  value: pdks.lateEmployeesCount.toString(),
                  color: AppColors.danger,
                  icon: Icons.alarm_off,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Hızlı Rol Yönetimi Kartı (Kısayol)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFD97706).withOpacity(0.12), const Color(0xFFB45309).withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rol ve Yetki Merkezi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Yeni kurumsal roller tanımlayın ve personellere atayın', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Departman Performansı & Devam Tablosu
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Departman Bazlı Devam Oranları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 16),
                _buildDeptRow(context, 'Yazılım & Ar-Ge Ekibi', 0.96, '5/6 Aktif', AppColors.primary),
                const SizedBox(height: 12),
                _buildDeptRow(context, 'İnsan Kaynakları', 1.0, '2/2 Aktif', AppColors.success),
                const SizedBox(height: 12),
                _buildDeptRow(context, 'Satış & Pazarlama', 0.88, '3/4 Aktif', AppColors.warning),
                const SizedBox(height: 12),
                _buildDeptRow(context, 'Mali İşler & Muhasebe', 0.94, '3/3 Aktif', AppColors.primary),
                const SizedBox(height: 12),
                _buildDeptRow(context, 'Operasyon & Saha', 0.90, '9/10 Aktif', AppColors.info),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Son Turnike Hareketleri
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Son Giriş & Turnike Hareketleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 12),
                ...pdks.records.take(4).map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            r.type == AttendanceType.checkIn ? Icons.login : Icons.logout,
                            size: 16,
                            color: r.type == AttendanceType.checkIn ? AppColors.success : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(r.employeeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                          const Spacer(),
                          Text(r.methodLabel, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ROL VE YETKİ YÖNETİMİ
  // Güvenlik Kuralı: Patron yeni roller ekleyebilir AMA admin rolünü ekleyemez/atayamaz!
  // ==========================================
  Widget _buildRoleManagementTab(BuildContext context, PdksState pdks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
      children: [
        // 1. Güvenlik Protokolü & Bilgilendirme Rozeti
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Patron Rol Yönetimi Yetki Sınırları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '• Patron olarak şirketinize özel yeni roller tanımlayabilir (örn: Departman Müdürü, Takım Lideri, Vardiya Amiri, Stajyer) ve personellere atayabilirsiniz.\n• Sistem Güvenliği: Sistem Yöneticisi (Admin) rolü teknik altyapı koruması nedeniyle Patron tarafından eklenemez, kimseye atanamaz ve mevcut Admin personeli değiştirilemez.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Rol Tanımları Başlığı ve "Yeni Rol Ekle" Butonu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanımlı Roller (${pdks.roles.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sistem ve Patron tarafından oluşturulan roller',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni Rol Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () => _showAddRoleDialog(context, pdks),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Roller Listesi
        ...pdks.roles.map((role) {
          final isAdminRole = role.baseRole == UserRole.admin || role.id == 'role_admin';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAdminRole
                    ? Colors.purple.withOpacity(0.3)
                    : AppColors.cardBorder(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: role.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(role.icon, color: role.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              role.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAdminRole)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 11, color: Colors.purple),
                                  SizedBox(width: 3),
                                  Text(
                                    'Korumalı Admin',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                                  ),
                                ],
                              ),
                            )
                          else if (!role.isSystemRole)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Özel Rol',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role.description,
                        style: TextStyle(color: AppColors.textSub(context), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taban Yetki: ${role.baseRole.label} • Ekleyen: ${role.createdBy}',
                        style: TextStyle(color: AppColors.textSub(context).withOpacity(0.7), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (!role.isSystemRole)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Bu Rolü Sil',
                    onPressed: () {
                      final res = pdks.deleteRole(role.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: res.success ? AppColors.success : Colors.red,
                          content: Text(res.message),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // 3. Personel Rol Atamaları Tablosu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personel Rol & Yetki Atamaları',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Personellere Personel, İK, Patron veya özel rollerinizi atayın',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...pdks.employees.map((emp) {
          final isEmpAdmin = emp.role == UserRole.admin;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isEmpAdmin
                    ? Colors.purple.withOpacity(0.3)
                    : AppColors.cardBorder(context),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isEmpAdmin
                        ? Colors.purple.withOpacity(0.15)
                        : const Color(0xFFD97706).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      emp.fullName.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEmpAdmin ? Colors.purple : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${emp.department} • ${emp.title}',
                        style: TextStyle(color: AppColors.textSub(context), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEmpAdmin
                                  ? Colors.purple.withOpacity(0.15)
                                  : emp.role == UserRole.boss
                                      ? Colors.orange.withOpacity(0.15)
                                      : emp.role == UserRole.hr
                                          ? AppColors.primary.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              emp.roleDisplayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isEmpAdmin
                                    ? Colors.purple
                                    : emp.role == UserRole.boss
                                        ? Colors.orange.shade800
                                        : emp.role == UserRole.hr
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Eğer personel Admin ise, Patron değiştiremez (Kilitli rozet göster)
                if (isEmpAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1A33) : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Admin (Kilitli)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      foregroundColor: AppColors.text(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.cardBorder(context)),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFD97706)),
                    label: const Text('Rol Ata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAssignRoleModal(context, pdks, emp),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // PATRON İÇİN YENİ ROL EKLEME MODALI
  // Güvenlik Kuralı: Patron Admin rolü ekleyemez!
  // ==========================================
  void _showAddRoleDialog(BuildContext context, PdksState pdks) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    UserRole selectedBase = UserRole.employee;
    Color selectedColor = const Color(0xFF0284C7);
    IconData selectedIcon = Icons.badge_outlined;

    final colorOptions = [
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFD97706), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF0D9488), // Teal
    ];

    final iconOptions = [
      Icons.badge_outlined,
      Icons.work_outline_rounded,
      Icons.military_tech_outlined,
      Icons.support_agent_rounded,
      Icons.groups_outlined,
      Icons.school_outlined,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_moderator_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Kurumsal Rol Tanımla',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Patron yetkisiyle şirket için yeni bir rol oluşturun',
                              style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Rol Adı
                  Text('Rol Adı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Örn: Departman Müdürü, Takım Lideri, Stajyer',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Rol Açıklaması
                  Text('Rol Açıklaması', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      hintText: 'Örn: Departman operasyonlarını ve izinleri yönetir',
                      prefixIcon: const Icon(Icons.description_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.inputBg(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Taban Yetki Düzeyi (Admin Engelli!)
                  Text('Taban Yetki Düzeyi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                  const SizedBox(height: 4),
                  Text('Bu role sahip olan kişinin kullanacağı ekran arayüzü', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                  const SizedBox(height: 8),

                  // 1. Personel Tabanı
                  _buildBaseRoleChoice(
                    title: 'Personel (Standart)',
                    subtitle: 'Giriş/çıkış, devam takibi, izin talebi ve dijital kartvizit',
                    icon: Icons.person_outline,
                    isSelected: selectedBase == UserRole.employee,
                    onTap: () => setSheetState(() => selectedBase = UserRole.employee),
                  ),
                  const SizedBox(height: 8),

                  // 2. İK Tabanı
                  _buildBaseRoleChoice(
                    title: 'İnsan Kaynakları (İK)',
                    subtitle: 'Personel listesi, vardiya takvimi, izin onayları ve puantaj raporları',
                    icon: Icons.people_alt_outlined,
                    isSelected: selectedBase == UserRole.hr,
                    onTap: () => setSheetState(() => selectedBase = UserRole.hr),
                  ),
                  const SizedBox(height: 8),

                  // 3. Patron Tabanı
                  _buildBaseRoleChoice(
                    title: 'Patron (Yönetim Kurulu)',
                    subtitle: 'Genel maliyetler, devam oranları ve rol yetkilendirmesi',
                    icon: Icons.workspace_premium_outlined,
                    isSelected: selectedBase == UserRole.boss,
                    onTap: () => setSheetState(() => selectedBase = UserRole.boss),
                  ),
                  const SizedBox(height: 8),

                  // 4. ADMIN SEÇENEĞİ: PATRON İÇİN KİLİTLİ!
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF171324) : const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_rounded, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistem Yöneticisi (Admin)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '🔒 Güvenlik Politikası: Patron seviyesinde Admin rolü veya Admin yetkisi eklenemez.',
                                style: TextStyle(fontSize: 11, color: Colors.purple),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Renk Seçici
                  Text('Rol Renk Teması', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  Row(
                    children: colorOptions.map((c) {
                      final isSel = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                            boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : null,
                          ),
                          child: isSel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // İkon Seçici
                  Text('Rol Simgesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  Row(
                    children: iconOptions.map((ic) {
                      final isSel = selectedIcon == ic;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedIcon = ic),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSel ? selectedColor.withOpacity(0.2) : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? selectedColor : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(ic, color: isSel ? selectedColor : (isDark ? Colors.white70 : Colors.black54), size: 20),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Rolü Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final res = pdks.addNewRole(
                              name: nameCtrl.text,
                              description: descCtrl.text,
                              baseRole: selectedBase,
                              color: selectedColor,
                              icon: selectedIcon,
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: res.success ? AppColors.success : Colors.red,
                                content: Text(res.message),
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
          );
        },
      ),
    );
  }

  Widget _buildBaseRoleChoice({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD97706).withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFD97706) : Colors.grey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFFD97706) : null)),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PATRON İÇİN PERSONELE ROL ATAMA MODALI
  // Güvenlik Kuralı: Patron personellere Admin rolü veremez!
  // ==========================================
  void _showAssignRoleModal(BuildContext context, PdksState pdks, Employee emp) {
    final availableRoles = pdks.rolesSelectableByBoss;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_pin_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${emp.fullName} • Rol Ata',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Şu anki Rol: ${emp.roleDisplayName}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Güvenlik Uyarısı
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Güvenlik gereği Admin rolü Patron tarafından personellere atanamaz.',
                      style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Rol Seçenekleri Listesi
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableRoles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final role = availableRoles[index];
                  final isCurrent = (!role.isSystemRole && emp.customRoleId == role.id) ||
                      (role.isSystemRole && emp.customRoleId == null && emp.role == role.baseRole);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final res = pdks.changeEmployeeRoleByActor(
                          employeeId: emp.id,
                          newBaseRole: role.baseRole,
                          customRoleId: role.isSystemRole ? null : role.id,
                          customRoleName: role.isSystemRole ? null : role.name,
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: res.success ? AppColors.success : Colors.red,
                            content: Text(res.message),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? role.color.withOpacity(0.12)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? role.color : AppColors.cardBorder(context),
                            width: isCurrent ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: role.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(role.icon, color: role.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isCurrent ? role.color : AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role.description,
                                    style: TextStyle(fontSize: 10, color: AppColors.textSub(context)),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(Icons.check_circle_rounded, color: role.color, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: PERSONEL KADROSU
  // ==========================================
  Widget _buildEmployeesTab(BuildContext context, PdksState pdks) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).padding.bottom + 24.0,
      ),
      children: [
        Text(
          'Şirket Personel Kadrosu (${pdks.employees.length})',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Tüm departmanlar, iletişim bilgileri ve unvanlar',
          style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
        ),
        const SizedBox(height: 16),

        ...pdks.employees.map((emp) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            emp.fullName.substring(0, 2).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('${emp.department} • ${emp.title}', style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: emp.role == UserRole.admin
                              ? Colors.purple.withOpacity(0.15)
                              : emp.role == UserRole.boss
                                  ? Colors.orange.withOpacity(0.15)
                                  : emp.role == UserRole.hr
                                      ? AppColors.primary.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emp.roleDisplayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: emp.role == UserRole.admin
                                ? Colors.purple
                                : emp.role == UserRole.boss
                                    ? Colors.orange.shade800
                                    : emp.role == UserRole.hr
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.cardBorder(context)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('İzin: ${emp.remainingLeaveDays} Gün Kalan', style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2563EB)),
                            tooltip: 'Ara',
                            onPressed: () {
                              final clean = emp.phone.replaceAll(RegExp(r'[^\d+]'), '');
                              launchUrl(Uri.parse('tel:$clean'));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF8B5CF6)),
                            tooltip: 'E-posta Gönder',
                            onPressed: () {
                              launchUrl(Uri.parse('mailto:${emp.email}'));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ==========================================
  // YARDIMCI BİLEŞENLER
  // ==========================================
  Widget _buildMetricTile(BuildContext context, {required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: AppColors.textSub(context))),
        ],
      ),
    );
  }

  Widget _buildDeptRow(BuildContext context, String name, double percent, String count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text(context))),
            Text(count, style: TextStyle(color: AppColors.textSub(context), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.cardBorder(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
