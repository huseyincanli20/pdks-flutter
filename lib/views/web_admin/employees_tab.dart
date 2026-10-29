import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee.dart';
import '../../state/pdks_state.dart';

class EmployeesTab extends StatelessWidget {
  const EmployeesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<PdksState>().employees;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        isMobile ? 16 : 28,
        MediaQuery.of(context).padding.bottom + (isMobile ? 16 : 28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personel Listesi (${employees.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 8 : 12),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'Ekle' : 'Yeni Personel Ekle', style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni personel ekleme formu açıldı.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: employees.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, index) {
                  final emp = employees[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      child: Text(
                        emp.fullName.substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (emp.role == UserRole.hr)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('İK', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Text('${emp.department} • ${emp.title}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Kalan İzin', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text('${emp.remainingLeaveDays} Gün', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
