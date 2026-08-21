import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                              AppStrings.appTitle,
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'HR Dashboard',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.sidebarText,
                                fontSize: 10,
                              ),
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
                  isCollapsed ? Icons.chevron_right : Icons.chevron_left,
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
                  item.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.sidebarTextActive : AppColors.sidebarText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
          dense: true,
          onTap: () {
            context.go(item.route);
          },
        ),
      ),
    );
  }
}
