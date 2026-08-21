import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_app/core/localization/app_localizations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../localization/app_strings.dart';
import '../../rbac/app_permission.dart';
import '../../rbac/app_role.dart';
import '../../rbac/authorization_service.dart';
import '../../routing/route_names.dart';

class NavItemData {
  final String label;
  final IconData icon;
  final String route;
  final AppPermission? requiredPermission;

  const NavItemData({
    required this.label,
    required this.icon,
    required this.route,
    this.requiredPermission,
  });
}

/// Navigation Sidebar for HR Dashboard
class HrSidebar extends StatelessWidget {
  final String currentRoute;
  final AppRole userRole;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const HrSidebar({
    super.key,
    required this.currentRoute,
    required this.userRole,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  static const List<NavItemData> _navItems = [
    NavItemData(
      label: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      route: RouteNames.dashboard,
    ),
    NavItemData(
      label: AppStrings.navEmployees,
      icon: Icons.people_alt_outlined,
      route: RouteNames.employees,
      requiredPermission: AppPermission.employeesRead,
    ),
    NavItemData(
      label: AppStrings.navAttendance,
      icon: Icons.access_time_outlined,
      route: RouteNames.attendance,
      requiredPermission: AppPermission.attendanceRead,
    ),
    NavItemData(
      label: AppStrings.navRequests,
      icon: Icons.assignment_outlined,
      route: RouteNames.requests,
      requiredPermission: AppPermission.requestsRead,
    ),
    NavItemData(
      label: AppStrings.navAdvances,
      icon: Icons.payments_outlined,
      route: RouteNames.advances,
      requiredPermission: AppPermission.advancesRead,
    ),
    NavItemData(
      label: AppStrings.navDeductions,
      icon: Icons.money_off_outlined,
      route: RouteNames.deductions,
      requiredPermission: AppPermission.deductionsRead,
    ),
    NavItemData(
      label: AppStrings.navWorkplaces,
      icon: Icons.location_on_outlined,
      route: RouteNames.workplaces,
      requiredPermission: AppPermission.workplacesRead,
    ),
    NavItemData(
      label: AppStrings.navSchedules,
      icon: Icons.calendar_month_outlined,
      route: RouteNames.schedules,
      requiredPermission: AppPermission.schedulesRead,
    ),
    NavItemData(
      label: AppStrings.navReports,
      icon: Icons.analytics_outlined,
      route: RouteNames.reports,
      requiredPermission: AppPermission.reportsRead,
    ),
    NavItemData(
      label: AppStrings.navNotifications,
      icon: Icons.notifications_none_outlined,
      route: RouteNames.notifications,
    ),
    NavItemData(
      label: AppStrings.navMessages,
      icon: Icons.mail_outline,
      route: RouteNames.messages,
    ),
    NavItemData(
      label: AppStrings.navAuditLogs,
      icon: Icons.history_edu_outlined,
      route: RouteNames.auditLogs,
      requiredPermission: AppPermission.auditLogsRead,
    ),
    NavItemData(
      label: AppStrings.navSettings,
      icon: Icons.settings_outlined,
      route: RouteNames.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = isCollapsed
        ? AppDimensions.sidebarWidthCollapsed
        : AppDimensions.sidebarWidthExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: effectiveWidth,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo & Branding Header
          Container(
            height: AppDimensions.topbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: isCollapsed
                ? const Center(
                    child: Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 28),
                  )
                : Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 28),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.translate('app_title'),
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.l10n.translate('hr_portal'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.sidebarText,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.space12,
                horizontal: AppDimensions.space8,
              ),
              children: _navItems.where((item) {
                if (item.requiredPermission == null) return true;
                return AuthorizationService.hasPermission(userRole, item.requiredPermission!);
              }).map((item) {
                final isSelected = currentRoute.startsWith(item.route);
                return _buildNavItem(context, item, isSelected);
              }).toList(),
            ),
          ),

          // Collapse/Expand Toggle
          if (onToggleCollapse != null)
            Container(
              padding: const EdgeInsets.all(AppDimensions.space8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: IconButton(
                icon: Icon(
                  isCollapsed
                      ? (context.l10n.isArabic ? Icons.chevron_left : Icons.chevron_right)
                      : (context.l10n.isArabic ? Icons.chevron_right : Icons.chevron_left),
                  color: AppColors.sidebarText,
                ),
                onPressed: onToggleCollapse,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItemData item, bool isSelected) {
    final localizedLabel = _getLocalizedNavLabel(context, item.route, item.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.sidebarActiveItem : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 16 : AppDimensions.space12,
            vertical: 0,
          ),
          leading: Icon(
            item.icon,
            size: 20,
            color: isSelected ? AppColors.primaryLight : AppColors.sidebarText,
          ),
          title: isCollapsed
              ? null
              : Text(
                  localizedLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.sidebarTextActive : AppColors.sidebarText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
          dense: true,
          onTap: () {
            context.go(item.route);
          },
        ),
      ),
    );
  }

  String _getLocalizedNavLabel(BuildContext context, String route, String fallback) {
    switch (route) {
      case RouteNames.dashboard:
        return context.l10n.translate('nav_dashboard');
      case RouteNames.employees:
        return context.l10n.translate('nav_employees');
      case RouteNames.attendance:
        return context.l10n.translate('nav_attendance');
      case RouteNames.requests:
        return context.l10n.translate('nav_requests');
      case RouteNames.advances:
        return context.l10n.translate('nav_advances');
      case RouteNames.deductions:
        return context.l10n.translate('nav_deductions');
      case RouteNames.workplaces:
        return context.l10n.translate('nav_workplaces');
      case RouteNames.schedules:
        return context.l10n.translate('nav_schedules');
      case RouteNames.reports:
        return context.l10n.translate('nav_reports');
      case RouteNames.notifications:
        return context.l10n.translate('nav_notifications');
      case RouteNames.messages:
        return context.l10n.translate('nav_messages');
      case RouteNames.auditLogs:
        return context.l10n.translate('nav_audit_logs');
      case RouteNames.settings:
        return context.l10n.translate('nav_settings');
      default:
        return fallback;
    }
  }
}
