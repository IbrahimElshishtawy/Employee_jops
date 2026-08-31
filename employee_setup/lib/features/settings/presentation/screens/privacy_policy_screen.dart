import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/mock/seeds/onboarding_catalog.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/settings_section.dart';

/// Professional enterprise Privacy Policy screen for the Employee application.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: context.tr('privacy.title'),
        subtitle: context.tr('privacy.subtitle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metadata Card (Last update & Corporate badge)
              _buildMetadataHeader(context, isDark),
              const SizedBox(height: 20),

              // 1. Introduction & Scope
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_intro_title'),
                content: context.tr('privacy.sec_intro_body'),
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // 2. Information We Process
              SettingsSection(
                title: context.tr('privacy.sec_collected_title'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubItem(
                          context,
                          isDark,
                          title: context.isArabic ? 'بيانات الحساب الوظيفي' : 'Account Information',
                          description: context.tr('privacy.sec_collected_account'),
                          icon: Icons.account_circle_outlined,
                        ),
                        const Divider(height: 24),
                        _buildSubItem(
                          context,
                          isDark,
                          title: context.isArabic ? 'بيانات الحضور والانصراف' : 'Attendance Data',
                          description: context.tr('privacy.sec_collected_attendance'),
                          icon: Icons.access_time_rounded,
                        ),
                        const Divider(height: 24),
                        _buildSubItem(
                          context,
                          isDark,
                          title: context.isArabic ? 'بيانات الجهاز الفنية' : 'Device Technical Data',
                          description: context.tr('privacy.sec_collected_device'),
                          icon: Icons.phonelink_setup_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Location Data Processing
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_location_title'),
                content: context.tr('privacy.sec_location_body'),
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 16),

              // 4. Usage of Information
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_usage_title'),
                content: context.tr('privacy.sec_usage_body'),
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.success,
              ),
              const SizedBox(height: 16),

              // 5. Data Security & Protection
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_security_title'),
                content: context.tr('privacy.sec_security_body'),
                icon: Icons.security_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),

              // 6. Data Confidentiality & Sharing
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_sharing_title'),
                content: context.tr('privacy.sec_sharing_body'),
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),

              // 7. Retention Period
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_retention_title'),
                content: context.tr('privacy.sec_retention_body'),
                icon: Icons.history_rounded,
                iconColor: const Color(0xFF64748B),
              ),
              const SizedBox(height: 16),

              // 8. Employee Rights & Contact
              _buildPolicySection(
                context,
                isDark,
                title: context.tr('privacy.sec_rights_title'),
                content: context.tr('privacy.sec_rights_body'),
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 20),

              // Official Contact Footer Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.isArabic ? 'استفسارات الخصوصية' : 'Privacy Inquiries',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            OnboardingCatalog.hrContact.email,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataHeader(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('privacy.last_updated'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(
    BuildContext context,
    bool isDark, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return SettingsSection(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubItem(
    BuildContext context,
    bool isDark, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
