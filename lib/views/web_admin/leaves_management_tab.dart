import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request.dart';
import '../../state/pdks_state.dart';

class LeavesManagementTab extends StatelessWidget {
  const LeavesManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final leaves = pdks.leaves;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personel İzin Talepleri & Onay Süreci (${leaves.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: leaves.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                itemBuilder: (_, index) {
                  final leave = leaves[index];
                  final isPending = leave.status == LeaveStatus.pending;

                  Color statusColor = AppColors.warning;
                  if (leave.status == LeaveStatus.approved) statusColor = AppColors.success;
                  if (leave.status == LeaveStatus.rejected) statusColor = AppColors.danger;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.beach_access, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(leave.typeLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      leave.statusLabel,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('dd.MM.yyyy').format(leave.startDate)} - ${DateFormat('dd.MM.yyyy').format(leave.endDate)} (${leave.totalDays} Gün) • Açıklama: "${leave.reason}"',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Aksiyon Butonları (Onayla / Reddet)
                        if (isPending)
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Reddet', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  pdks.updateLeaveStatus(leave.id, LeaveStatus.rejected);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('İzin talebi reddedildi.')),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Onayla', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  pdks.updateLeaveStatus(leave.id, LeaveStatus.approved);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.success,
                                      content: Text('İzin talebi onaylandı ve bakiye düşürüldü.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          Text(
                            leave.managerComment ?? 'İşlem tamamlandı',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
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
