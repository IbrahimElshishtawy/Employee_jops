import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/cards/chart_card.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/loading_state_view.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../controllers/dashboard_controller.dart';

/// Main Dashboard Overview Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    if (controller.isLoading && controller.metrics == null) {
      return const LoadingStateView(message: 'Loading dashboard metrics...');
    }

    if (controller.errorMessage != null && controller.metrics == null) {
      return ErrorStateView(
        message: controller.errorMessage!,
        onRetry: () => controller.loadMetrics(),
      );
    }

    final m = controller.metrics;
    if (m == null) return const SizedBox.shrink();

    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Welcome Banner
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome to CyberWise IE HR Portal', style: AppTypography.heading2),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Monitor workforce operations, attendance, leaves, and approvals in real-time.',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppDimensions.space16),
                  HrButton(
                    label: 'New Employee',
                    icon: Icons.person_add_outlined,
                    onPressed: () => context.go(RouteNames.employees),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space24),

        // Primary KPI Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth;
            if (constraints.maxWidth > 1100) {
              cardWidth = (constraints.maxWidth - (AppDimensions.space16 * 3)) / 4;
            } else if (constraints.maxWidth > 650) {
              cardWidth = (constraints.maxWidth - AppDimensions.space16) / 2;
            } else {
              cardWidth = constraints.maxWidth;
            }

            return Wrap(
              spacing: AppDimensions.space16,
              runSpacing: AppDimensions.space16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Total Workforce',
                    value: '${m.totalEmployees}',
                    subtitle: 'Active roster',
                    icon: Icons.people_outline,
                    iconColor: AppColors.primaryLight,
                    onTap: () => context.go(RouteNames.employees),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Present Today',
                    value: '${m.presentToday}',
                    subtitle: '${m.attendanceRate}% on-time',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.success,
                    trend: '+4.2%',
                    isPositiveTrend: true,
                    onTap: () => context.go(RouteNames.attendance),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Late Arrivals',
                    value: '${m.lateToday}',
                    subtitle: 'Today records',
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.warning,
                    onTap: () => context.go(RouteNames.attendance),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Absent',
                    value: '${m.absentToday}',
                    subtitle: 'Unexcused / Leave',
                    icon: Icons.highlight_off_outlined,
                    iconColor: AppColors.danger,
                    onTap: () => context.go(RouteNames.attendance),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Pending Requests',
                    value: '${m.pendingRequests}',
                    subtitle: 'Requires action',
                    icon: Icons.assignment_late_outlined,
                    iconColor: AppColors.accent,
                    onTap: () => context.go(RouteNames.requests),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Pending Advances',
                    value: '${m.pendingAdvances}',
                    subtitle: 'Salary requests',
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.secondary,
                    onTap: () => context.go(RouteNames.advances),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Today Check-ins',
                    value: '${m.checkInsToday}',
                    subtitle: 'Clock-in logs',
                    icon: Icons.login_outlined,
                    iconColor: AppColors.info,
                    onTap: () => context.go(RouteNames.attendance),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    title: 'Today Check-outs',
                    value: '${m.checkOutsToday}',
                    subtitle: 'Clock-out logs',
                    icon: Icons.logout_outlined,
                    iconColor: AppColors.neutral,
                    onTap: () => context.go(RouteNames.attendance),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppDimensions.space24),

        // Analytical & Quick Overview Breakdown
        ChartCard(
          title: 'Daily Attendance Distribution',
          subtitle: 'Live status breakdown across all registered company workplaces',
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      Expanded(
                        flex: m.presentToday,
                        child: Container(color: AppColors.success),
                      ),
                      Expanded(
                        flex: m.lateToday,
                        child: Container(color: AppColors.warning),
                      ),
                      Expanded(
                        flex: m.absentToday,
                        child: Container(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Present (${m.presentToday})', AppColors.success),
                  _buildLegendItem('Late (${m.lateToday})', AppColors.warning),
                  _buildLegendItem('Absent (${m.absentToday})', AppColors.danger),
                ],
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.captionBold),
      ],
    );
  }
}
