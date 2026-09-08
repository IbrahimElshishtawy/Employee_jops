import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/payslip_record.dart';

class PayslipDetailsScreen extends StatelessWidget {
  final PayslipRecord payslip;

  const PayslipDetailsScreen({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isRtl ? "مفردات مرتب" : "Payslip"} ${payslip.month}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Net Pay Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isRtl ? 'صافي الراتب المحول' : 'Net Salary Paid',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${payslip.netSalary.toStringAsFixed(0)} ${payslip.currency}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (payslip.paymentDate != null)
                    Text(
                      '${isRtl ? "تاريخ التحويل:" : "Payment Date:"} ${DateFormat('yyyy-MM-dd').format(payslip.paymentDate!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Totals
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'إجمالي المستحقات' : 'Total Earnings',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${(payslip.basicSalary + payslip.totalAllowances).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'إجمالي الاستقطاعات' : 'Total Deductions',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${payslip.totalDeductions.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Earnings Breakdown
            Text(
              isRtl ? 'المستحقات والبدلات' : 'Earnings & Allowances',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildItemRow(isRtl ? 'الراتب الأساسي' : 'Basic Salary', payslip.basicSalary, false),
            for (final item in payslip.earnings)
              _buildItemRow(item.label, item.amount, false),
            const SizedBox(height: 20),

            // Deductions Breakdown
            Text(
              isRtl ? 'الاستقطاعات والخصومات' : 'Deductions & Withholdings',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final item in payslip.deductions)
              _buildItemRow(item.label, item.amount, true),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String label, double amount, bool isDeduction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${isDeduction ? "-" : "+"}${amount.toStringAsFixed(0)} ${payslip.currency}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDeduction ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
