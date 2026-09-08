import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/datasources/payroll_remote_data_source.dart';
import '../../data/repositories/payroll_repository.dart';
import '../../domain/models/salary_structure.dart';

final payrollRemoteDataSourceProvider = Provider<PayrollRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return PayrollRemoteDataSource(client);
});

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final ds = ref.watch(payrollRemoteDataSourceProvider);
  return RealPayrollRepository(ds);
});

final salaryStructureProvider = FutureProvider.autoDispose<SalaryStructure>((ref) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getSalaryStructure();
});

class SalaryStructureScreen extends ConsumerWidget {
  const SalaryStructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = context.isRtl;
    final salaryAsync = ref.watch(salaryStructureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'هيكل ومفردات الراتب' : 'Salary Structure'),
      ),
      body: salaryAsync.when(
        data: (salary) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Gross Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'إجمالي الراتب الشامل' : 'Total Gross Salary',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            salary.totalGrossSalary.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            salary.currency,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Breakdown Items
                Text(
                  isRtl ? 'تفاصيل بنود الراتب والبدلات' : 'Allowances & Breakdown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBreakdownCard(
                  context,
                  title: isRtl ? 'الراتب الأساسي' : 'Basic Salary',
                  amount: salary.basicSalary,
                  currency: salary.currency,
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildBreakdownCard(
                  context,
                  title: isRtl ? 'بدل سكن' : 'Housing Allowance',
                  amount: salary.housingAllowance,
                  currency: salary.currency,
                  icon: Icons.home_rounded,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                _buildBreakdownCard(
                  context,
                  title: isRtl ? 'بدل انتقال' : 'Transportation Allowance',
                  amount: salary.transportationAllowance,
                  currency: salary.currency,
                  icon: Icons.directions_bus_rounded,
                  color: Colors.green,
                ),
                if (salary.otherAllowances > 0) ...[
                  const SizedBox(height: 8),
                  _buildBreakdownCard(
                    context,
                    title: isRtl ? 'بدلات إضافية' : 'Other Allowances',
                    amount: salary.otherAllowances,
                    currency: salary.currency,
                    icon: Icons.card_giftcard_rounded,
                    color: Colors.purple,
                  ),
                ],
                for (final item in salary.customAllowances) ...[
                  const SizedBox(height: 8),
                  _buildBreakdownCard(
                    context,
                    title: item.name,
                    amount: item.amount,
                    currency: salary.currency,
                    icon: Icons.star_rounded,
                    color: Colors.teal,
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context, {
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
