import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_dimensions.dart';
import '../../rbac/app_role.dart';
import '../../utils/responsive_layout.dart';
import 'hr_sidebar.dart';
import 'hr_topbar.dart';

/// Responsive Layout Shell Container
class HrScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final AppRole userRole;
  final String userName;
  final VoidCallback? onLogout;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationsTap;

  const HrScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.userRole = AppRole.superAdmin,
    this.userName = 'HR Admin',
    this.onLogout,
    this.unreadNotificationsCount = 0,
    this.onNotificationsTap,
  });

  @override
  State<HrScaffold> createState() => _HrScaffoldState();
}

class _HrScaffoldState extends State<HrScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: HrSidebar(
                currentRoute: widget.currentRoute,
                userRole: widget.userRole,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            HrSidebar(
              currentRoute: widget.currentRoute,
              userRole: widget.userRole,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          Expanded(
            child: Column(
              children: [
                HrTopbar(
                  title: widget.title,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  onLogout: widget.onLogout,
                  unreadNotificationsCount: widget.unreadNotificationsCount,
                  onNotificationsTap: widget.onNotificationsTap,
                  onMenuPressed: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
