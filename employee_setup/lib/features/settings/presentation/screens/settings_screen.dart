import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('settings.title'),
        subtitle: 'تخصيص المظهر، اللغة، وأدوات الاختبار',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Appearance / Theme Section
            SettingsSection(
              title: context.tr('settings.appearance'),
              children: [
                ListTile(
                  title: Text(
                    context.tr('settings.theme'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    _getThemeName(settings.themeMode, context),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox.shrink(),
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(settingsProvider.notifier).setThemeMode(mode);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(context.tr('settings.theme_system')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(context.tr('settings.theme_light')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(context.tr('settings.theme_dark')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Language Section
            SettingsSection(
              title: context.tr('settings.language'),
              children: [
                ListTile(
                  title: Text(
                    context.tr('settings.language'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    settings.locale.languageCode == 'ar'
                        ? context.tr('settings.language_ar')
                        : context.tr('settings.language_en'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  trailing: DropdownButton<String>(
                    value: settings.locale.languageCode,
                    underline: const SizedBox.shrink(),
                    onChanged: (code) {
                      if (code != null) {
                        ref.read(settingsProvider.notifier).setLocale(Locale(code));
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(context.tr('settings.language_ar')),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(context.tr('settings.language_en')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Chat & Messaging Settings
            SettingsSection(
              title: context.isArabic ? 'إعدادات المحادثات والتواصل' : 'Chat & Messaging',
              children: [
                ListTile(
                  title: Text(
                    context.isArabic ? 'إعدادات المحادثات' : 'Chat Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'الإشعارات، الخصوصية، التخزين، والأمان البيومتري'
                        : 'Notifications, privacy, storage & security',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.chatSettings),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Developer / Demo Controls (Shown in Debug and Demo test mode)
            SettingsSection(
              title: context.tr('settings.developer_demo'),
              children: [
                ListTile(
                  title: Text(
                    context.tr('demo.title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('settings.demo_desc'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push('/settings/demo'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Help & Support & Policies
            SettingsSection(
              title: context.isArabic ? 'المساعدة والسياسات' : 'Help & Policies',
              children: [
                ListTile(
                  title: Text(
                    context.tr('help.title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic ? 'الأسئلة الشائعة ودليل استخدام التطبيق' : 'FAQs and guide',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_center_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.helpCenter),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    context.tr('support.title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic ? 'تقديم بلاغ تقني أو استفسار فني' : 'Submit a report or inquiry',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.support),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    context.tr('privacy.title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic ? 'حماية البيانات والخصوصية' : 'Data protection & privacy',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF10B981), size: 20),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. About Application
            SettingsSection(
              title: context.tr('about.section_app'),
              children: [
                ListTile(
                  title: const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${context.tr('about.version')} ${AppConstants.appVersion} (${context.tr('about.build')} ${AppConstants.appBuild})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.system:
        return context.tr('settings.theme_system');
      case ThemeMode.light:
        return context.tr('settings.theme_light');
      case ThemeMode.dark:
        return context.tr('settings.theme_dark');
    }
  }
}
