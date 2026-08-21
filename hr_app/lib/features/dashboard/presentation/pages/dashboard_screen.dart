import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
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
    final l10n = context.l10n;

    if (controller.isLoading && controller.metrics == null) {
      return LoadingStateView(message: l10n.translate('loading'));
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
                        Text(l10n.translate('dash_welcome'), style: AppTypography.heading2),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          l10n.translate('dash_welcome_sub'),
                          style: AppTypography.subtitleOf(context),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: AppDimensions.space16),
                    HrButton(
                      label: l10n.translate('dash_new_employee'),
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
                      title: l10n.translate('dash_total_workforce'),
                      value: l10n.formatNumber(m.totalEmployees),
                      subtitle: l10n.translate('dash_active_roster'),
                      icon: Icons.people_outline,
                      iconColor: AppColors.primaryLight,
                      onTap: () => context.go(RouteNames.employees),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_present_today'),
                      value: l10n.formatNumber(m.presentToday),
                      subtitle: '${m.attendanceRate}% ${l10n.translate("dash_on_time")}',
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
                      title: l10n.translate('dash_late_arrivals'),
                      value: l10n.formatNumber(m.lateToday),
                      subtitle: l10n.translate('dash_today_records'),
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.warning,
                      onTap: () => context.go(RouteNames.attendance),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_absent'),
                      value: l10n.formatNumber(m.absentToday),
                      subtitle: l10n.translate('dash_absent_sub'),
                      icon: Icons.highlight_off_outlined,
                      iconColor: AppColors.danger,
                      onTap: () => context.go(RouteNames.attendance),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_pending_requests'),
                      value: l10n.formatNumber(m.pendingRequests),
                      subtitle: l10n.translate('dash_requires_action'),
                      icon: Icons.assignment_late_outlined,
                      iconColor: AppColors.accent,
                      onTap: () => context.go(RouteNames.requests),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_pending_advances'),
                      value: l10n.formatNumber(m.pendingAdvances),
                      subtitle: l10n.translate('dash_salary_requests'),
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.secondary,
                      onTap: () => context.go(RouteNames.advances),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_checkins_today'),
                      value: l10n.formatNumber(m.checkInsToday),
                      subtitle: l10n.translate('dash_clockin_logs'),
                      icon: Icons.login_outlined,
                      iconColor: AppColors.info,
                      onTap: () => context.go(RouteNames.attendance),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      title: l10n.translate('dash_checkouts_today'),
                      value: l10n.formatNumber(m.checkOutsToday),
                      subtitle: l10n.translate('dash_clockout_logs'),
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
            title: l10n.translate('dash_chart_title'),
            subtitle: l10n.translate('dash_chart_sub'),
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
                    _buildLegendItem('${l10n.translate("dash_present_count")} (${l10n.formatNumber(m.presentToday)})', AppColors.success),
                    _buildLegendItem('${l10n.translate("dash_late_count")} (${l10n.formatNumber(m.lateToday)})', AppColors.warning),
                    _buildLegendItem('${l10n.translate("dash_absent_count")} (${l10n.formatNumber(m.absentToday)})', AppColors.danger),
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
