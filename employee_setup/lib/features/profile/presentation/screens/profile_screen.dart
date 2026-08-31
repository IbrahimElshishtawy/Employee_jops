import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/domain/models/employee.dart';
import '../widgets/employee_info_card.dart';
import '../widgets/profile_menu_item.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('auth.logout')),
        content: Text(context.tr('auth.logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(context.tr('auth.logout')),
          ),
        ],
      ),
    );
  }

  void _showSimpleInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider) ?? Employee.defaultMock;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('profile.title'),
        subtitle: 'بيانات الموظف وإعدادات الحساب',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Column(
          children: [
            // 1. Employee Info Hero Card
            EmployeeInfoCard(employee: employee),
            const SizedBox(height: 20),

            // 2. Main Actions Menu Card
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileMenuItem(
                    title: context.tr('settings.title'),
                    subtitle: 'المظهر، اللغة، وأدوات المطور',
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(),
                  ProfileMenuItem(
                    title: context.tr('profile.help'),
                    subtitle: context.isArabic ? 'الأسئلة الشائعة ومركز الدعم الفني' : 'FAQs & technical support',
                    icon: Icons.help_outline_rounded,
                    onTap: () => context.push(AppRoutes.helpCenter),
                  ),
                  const Divider(),
                  ProfileMenuItem(
                    title: context.tr('profile.privacy'),
                    subtitle: context.isArabic ? 'سياسة الخصوصية وأمان البيانات' : 'Data protection & privacy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  const Divider(),
                  ProfileMenuItem(
                    title: context.tr('about.title'),
                    subtitle: '${context.tr('about.version')} ${AppConstants.appVersion} (${context.tr('about.build')} ${AppConstants.appBuild})',
                    icon: Icons.info_outline_rounded,
                    onTap: () => context.push(AppRoutes.about),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Logout Action Card
            AppCard(
              padding: EdgeInsets.zero,
              child: ProfileMenuItem(
                title: context.tr('auth.logout'),
                subtitle: 'إنهاء الجلسة والعودة لشاشة الدخول',
                icon: Icons.logout_rounded,
                isDestructive: true,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

