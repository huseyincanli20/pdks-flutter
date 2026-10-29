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
          Text(
            'İzin Talepleri & Onay Süreci (${leaves.length})',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: leaves.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final leave = leaves[index];
                final isPending = leave.status == LeaveStatus.pending;

                Color statusColor = AppColors.warning;
                if (leave.status == LeaveStatus.approved) statusColor = AppColors.success;
                if (leave.status == LeaveStatus.rejected) statusColor = AppColors.danger;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.beach_access, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        leave.employeeName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: AppColors.text(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.subtle(context),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.cardBorder(context)),
                                      ),
                                      child: Text(
                                        leave.typeLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.text(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat('dd.MM.yyyy').format(leave.startDate)} - ${DateFormat('dd.MM.yyyy').format(leave.endDate)} (${leave.totalDays} Gün)',
                                  style: TextStyle(color: AppColors.textSub(context), fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.35)),
                            ),
                            child: Text(
                              leave.statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.subtle(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder(context)),
                        ),
                        child: Text(
                          '"${leave.reason}"',
                          style: TextStyle(fontSize: 12, color: AppColors.text(context), fontStyle: FontStyle.italic),
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('Reddet', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  pdks.updateLeaveStatus(leave.id, LeaveStatus.rejected);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('İzin talebi reddedildi.')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.check, size: 14),
                                label: const Text('Onayla', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  pdks.updateLeaveStatus(leave.id, LeaveStatus.approved);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.success,
                                      content: Text('İzin talebi onaylandı.'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
