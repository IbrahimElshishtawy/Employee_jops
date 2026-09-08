import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/payslip_record.dart';
import 'payslip_details_screen.dart';
import 'salary_structure_screen.dart';

final myPayslipsProvider = FutureProvider.autoDispose<List<PayslipRecord>>((ref) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getPayslips();
});

class PayslipsListScreen extends ConsumerWidget {
  const PayslipsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final payslipsAsync = ref.watch(myPayslipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'مسيرات الرواتب الشهرية' : 'Monthly Payslips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: isRtl ? 'هيكل الراتب' : 'Salary Structure',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalaryStructureScreen()),
              );
            },
          ),
        ],
      ),
      body: payslipsAsync.when(
        data: (payslips) {
          if (payslips.isEmpty) {
            return Center(
              child: Text(isRtl ? 'لا توجد قسائم رواتب صادرة' : 'No payslips found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPayslipsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payslips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final slip = payslips[index];
                final isPaid = slip.paymentStatus.toUpperCase() == 'PAID';

                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayslipDetailsScreen(payslip: slip),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (isPaid ? Colors.green : Colors.amber)
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: isPaid ? Colors.green : Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isRtl ? "راتب شهر" : "Salary for"} ${slip.month}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${isRtl ? "صافي المستحق:" : "Net Pay:"} ${slip.netSalary.toStringAsFixed(0)} ${slip.currency}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isPaid ? Colors.green : Colors.amber)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? (isRtl ? 'تم الصرف' : 'PAID') : slip.paymentStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
