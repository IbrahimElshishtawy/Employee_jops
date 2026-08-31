import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/mock/seeds/onboarding_catalog.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_logo.dart';
import '../widgets/about_action_tile.dart';
import '../widgets/about_feature_item.dart';
import '../widgets/settings_section.dart';

/// Professional enterprise About App screen providing identity, description,
/// features, support, legal details, company information, and versioning.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: context.tr('about.title'),
        subtitle: context.tr('about.subtitle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. App Identity Header Card
              _buildAppIdentityHeader(context, isDark),
              const SizedBox(height: 20),

              // 2. About Application Overview Section
              SettingsSection(
                title: context.tr('about.section_app'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      context.tr('about.app_description'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Main Features Section
              SettingsSection(
                title: context.tr('about.section_features'),
                children: [
                  AboutFeatureItem(
                    icon: Icons.timer_rounded,
                    title: context.tr('about.feature_attendance'),
                    description: context.tr('about.feature_attendance_desc'),
                    iconColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  AboutFeatureItem(
                    icon: Icons.assignment_turned_in_rounded,
                    title: context.tr('about.feature_requests'),
                    description: context.tr('about.feature_requests_desc'),
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                  const Divider(height: 1),
                  AboutFeatureItem(
                    icon: Icons.forum_rounded,
                    title: context.tr('about.feature_communication'),
                    description: context.tr('about.feature_communication_desc'),
                    iconColor: const Color(0xFF0EA5E9),
                  ),
                  const Divider(height: 1),
                  AboutFeatureItem(
                    icon: Icons.notifications_active_rounded,
                    title: context.tr('about.feature_notifications'),
                    description: context.tr('about.feature_notifications_desc'),
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  const Divider(height: 1),
                  AboutFeatureItem(
                    icon: Icons.account_circle_rounded,
                    title: context.tr('about.feature_profile'),
                    description: context.tr('about.feature_profile_desc'),
                    iconColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Support & Help Section
              SettingsSection(
                title: context.tr('about.section_support'),
                children: [
                  AboutActionTile(
                    icon: Icons.help_center_rounded,
                    title: context.tr('about.help_center'),
                    subtitle: context.tr('about.help_center_desc'),
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () => _handleHelpCenter(context),
                  ),
                  const Divider(height: 1),
                  AboutActionTile(
                    icon: Icons.support_agent_rounded,
                    title: context.tr('about.contact_support'),
                    subtitle: context.tr('about.contact_support_desc'),
                    iconColor: AppColors.primary,
                    onTap: () => _handleContactSupport(context),
                  ),
                  const Divider(height: 1),
                  AboutActionTile(
                    icon: Icons.bug_report_rounded,
                    title: context.tr('about.report_problem'),
                    subtitle: context.tr('about.report_problem_desc'),
                    iconColor: const Color(0xFFE11D48),
                    onTap: () => _handleReportProblem(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Legal Section
              SettingsSection(
                title: context.tr('about.section_legal'),
                children: [
                  AboutActionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: context.tr('about.privacy_policy'),
                    subtitle: context.tr('about.privacy_policy_desc'),
                    iconColor: const Color(0xFF10B981),
                    onTap: () => _showInfoDialog(
                      context,
                      context.tr('about.privacy_dialog_title'),
                      context.tr('about.privacy_dialog_content'),
                      Icons.privacy_tip_outlined,
                    ),
                  ),
                  const Divider(height: 1),
                  AboutActionTile(
                    icon: Icons.gavel_rounded,
                    title: context.tr('about.terms_of_use'),
                    subtitle: context.tr('about.terms_of_use_desc'),
                    iconColor: const Color(0xFF6366F1),
                    onTap: () => _showInfoDialog(
                      context,
                      context.tr('about.terms_dialog_title'),
                      context.tr('about.terms_dialog_content'),
                      Icons.gavel_rounded,
                    ),
                  ),
                  const Divider(height: 1),
                  AboutActionTile(
                    icon: Icons.code_rounded,
                    title: context.tr('about.open_source_licenses'),
                    subtitle: context.tr('about.open_source_licenses_desc'),
                    iconColor: const Color(0xFF64748B),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion:
                          '${AppConstants.appVersion} (${context.tr('about.build')} ${AppConstants.appBuild})',
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: AppLogo(size: 64, iconSize: 32, showShadow: false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Company Information Section
              SettingsSection(
                title: context.tr('about.section_company'),
                children: [
                  AboutActionTile(
                    icon: Icons.business_rounded,
                    title: context.tr('about.company_name'),
                    subtitle: AppConstants.appName,
                    iconColor: AppColors.primary,
                    trailing: const SizedBox.shrink(),
                  ),
                  if (OnboardingCatalog.hrContact.email.isNotEmpty) ...[
                    const Divider(height: 1),
                    AboutActionTile(
                      icon: Icons.email_outlined,
                      title: context.tr('about.company_email'),
                      subtitle: OnboardingCatalog.hrContact.email,
                      iconColor: const Color(0xFF0EA5E9),
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                  const Divider(height: 1),
                  AboutActionTile(
                    icon: Icons.verified_user_rounded,
                    title: context.isArabic ? 'نوع المنظومة' : 'Platform Type',
                    subtitle: context.isArabic
                        ? 'حلول الموارد البشرية والخدمات الذاتية'
                        : 'Enterprise HR Self-Service Platform',
                    iconColor: AppColors.success,
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 7. Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '© $currentYear ${AppConstants.appName}. ${context.tr('about.all_rights_reserved')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIdentityHeader(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          const AppLogo(
            size: 72,
            iconSize: 38,
            borderRadius: 20,
            showShadow: true,
            isWhiteCardStyle: false,
          ),
          const SizedBox(height: 14),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('about.subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${context.tr('about.version')} ${AppConstants.appVersion} (${context.tr('about.build')} ${AppConstants.appBuild})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleHelpCenter(BuildContext context) {
    _showInfoDialog(
      context,
      context.tr('about.help_center'),
      context.tr('about.support_dialog_content'),
      Icons.help_center_rounded,
    );
  }

  void _handleContactSupport(BuildContext context) {
    // Check if communication route is available
    context.push(AppRoutes.departments);
  }

  void _handleReportProblem(BuildContext context) {
    context.push(AppRoutes.newDepartmentRequest);
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('common.back'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
