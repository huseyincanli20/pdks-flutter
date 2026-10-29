import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';
import '../common/app_drawer.dart';
import '../web_admin/dashboard_tab.dart';
import '../web_admin/employees_tab.dart';
import '../web_admin/shifts_tab.dart';
import '../web_admin/leaves_management_tab.dart';
import '../web_admin/reports_puantaj_tab.dart';

class HrShell extends StatefulWidget {
  const HrShell({super.key});

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'İK Genel Bakış',
    'Personel Listesi',
    'Vardiya Takvimi',
    'İzin Talepleri',
    'Aylık Puantaj',
  ];

  final List<Widget> _tabs = const [
    DashboardTab(),
    EmployeesTab(),
    ShiftsTab(),
    LeavesManagementTab(),
    ReportsPuantajTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<PdksState>().currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İK Paneli • ${_titles[_currentIndex]}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${user.fullName} (${user.title})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 14),
                SizedBox(width: 4),
                Text('İK Yetkisi', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Personel',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Vardiya',
          ),
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(Icons.beach_access, color: AppColors.primary),
            label: 'İzinler',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment, color: AppColors.primary),
            label: 'Puantaj',
          ),
        ],
      ),
    );
  }
}
