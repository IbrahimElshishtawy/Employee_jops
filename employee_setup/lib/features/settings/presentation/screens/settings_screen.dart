import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
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

            // 3. Developer / Demo Controls (Shown in Debug and Demo test mode)
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
