import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/forms/hr_button.dart';

/// Operational & Analytical Reports Screen
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Operational Reports & Data Exports', style: AppTypography.heading2),
          const SizedBox(height: AppDimensions.space8),
          Text('Generate, view, and export workforce analytics.', style: AppTypography.subtitleOf(context)),
          const SizedBox(height: AppDimensions.space24),

          Wrap(
            spacing: AppDimensions.space16,
            runSpacing: AppDimensions.space16,
            children: [
              _buildReportCard(
                context,
                title: 'Monthly Attendance Summary',
                description: 'Detailed check-in, check-out, tardiness, and overtime records across departments.',
                icon: Icons.calendar_today_outlined,
              ),
              _buildReportCard(
                context,
                title: 'Leave & Absences Audit',
                description: 'Historical records of all approved, rejected, and pending leaves by reason.',
                icon: Icons.assignment_turned_in_outlined,
              ),
              _buildReportCard(
                context,
                title: 'Salary Advances & Deductions',
                description: 'Payroll adjustments, disbursements, and disciplinary deduction breakdowns.',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildReportCard(
                context,
                title: 'Workplace Geofencing Compliance',
                description: 'Analysis of attendance punches within allowed workplace radii vs rejected attempts.',
                icon: Icons.pin_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, {required String title, required String description, required IconData icon}) {
    return SizedBox(
      width: 480,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(icon, color: AppColors.primaryLight, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: Text(title, style: AppTypography.heading3),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(description, style: AppTypography.body),
              const SizedBox(height: AppDimensions.space20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Export CSV',
                    variant: HrButtonVariant.outline,
                    icon: Icons.file_download_outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting report...')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
