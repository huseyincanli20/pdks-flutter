import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  String _selectedDept = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<PdksState>().employees;

    final departments = ['Tümü', ...employees.map((e) => e.department).toSet()];

    final filtered = employees.where((e) {
      final matchesSearch = e.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.department.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDept == 'Tümü' || e.department == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirket Rehberi (Kişiler)'),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'İsim, unvan veya departman ara...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Departman Filtre Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: departments.map((dept) {
                final isSelected = _selectedDept == dept;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedDept = dept),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Liste
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Aramanızla eşleşen personel bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final emp = filtered[index];
                      return _buildContactCard(context, emp);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Employee emp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            child: Text(
              emp.fullName.isNotEmpty ? emp.fullName.substring(0, 2).toUpperCase() : 'P',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (emp.role == UserRole.hr) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('İK', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${emp.department} • ${emp.title}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(emp.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
            tooltip: 'Ara',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${emp.fullName} aranıyor: ${emp.phone}')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
            tooltip: 'E-Posta Gönder',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${emp.email} adresine e-posta gönderimi açıldı.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
