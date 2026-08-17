import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../attendance/data/services/mock_biometric_service.dart';
import '../../../attendance/data/services/mock_location_service.dart';
import '../widgets/settings_section.dart';

class DeveloperDemoScreen extends ConsumerWidget {
  const DeveloperDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('demo.title'),
        subtitle: 'محاكاة الحالات وسيناريوهات الاختبار الحي',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Location Simulation
            SettingsSection(
              title: context.tr('demo.location_heading'),
              children: [
                _buildRadioTile<MockLocationMode>(
                  title: context.tr('demo.location_inside'),
                  subtitle: 'المسافة: 2.3 متر من مقر الشركة',
                  value: MockLocationMode.insideRange,
                  groupValue: demo.locationMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setLocationMode(mode, 2.3);
                    }
                  },
                ),
                const Divider(),
                _buildRadioTile<MockLocationMode>(
                  title: context.tr('demo.location_outside'),
                  subtitle: 'المسافة: 48.5 متر (سيتم منع التسجيل)',
                  value: MockLocationMode.outsideRange,
                  groupValue: demo.locationMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setLocationMode(mode, 48.5);
                    }
                  },
                ),
                const Divider(),
                _buildRadioTile<MockLocationMode>(
                  title: context.tr('demo.location_denied'),
                  subtitle: 'محاكاة عدم إعطاء صلاحية الموقع',
                  value: MockLocationMode.permissionDenied,
                  groupValue: demo.locationMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setLocationMode(mode);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Biometric Simulation
            SettingsSection(
              title: context.tr('demo.biometric_heading'),
              children: [
                _buildRadioTile<MockBiometricMode>(
                  title: context.tr('demo.biometric_success'),
                  subtitle: 'المصادقة ببصمة الإصبع أو الوجه تنجح فورًا',
                  value: MockBiometricMode.alwaysSuccess,
                  groupValue: demo.biometricMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setBiometricMode(mode);
                    }
                  },
                ),
                const Divider(),
                _buildRadioTile<MockBiometricMode>(
                  title: context.tr('demo.biometric_failed'),
                  subtitle: 'فشل البصمة وتنبيه المستخدم لإعادة المحاولة',
                  value: MockBiometricMode.alwaysFail,
                  groupValue: demo.biometricMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setBiometricMode(mode);
                    }
                  },
                ),
                const Divider(),
                _buildRadioTile<MockBiometricMode>(
                  title: context.tr('demo.biometric_cancelled'),
                  subtitle: 'إلغاء نافذة البصمة من قبل المستخدم',
                  value: MockBiometricMode.alwaysCancel,
                  groupValue: demo.biometricMode,
                  isDark: isDark,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(demoControlsProvider.notifier).setBiometricMode(mode);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Network Connectivity Simulation
            SettingsSection(
              title: context.tr('demo.network_heading'),
              children: [
                SwitchListTile(
                  title: Text(
                    demo.isOnline ? context.tr('demo.network_online') : context.tr('demo.network_offline'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    demo.isOnline
                        ? 'الاتصال بالإنترنت نشط والمزامنة مباشرة'
                        : 'وضع عدم الاتصال: يتم حفظ الحضور محليًا ووضعه في انتظار مراجعة الـ HR',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  value: demo.isOnline,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(demoControlsProvider.notifier).setNetworkOnline(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Reset All Demo Data
            AppButton.danger(
              label: context.tr('demo.reset_data'),
              icon: Icons.restore_rounded,
              onPressed: () async {
                await ref.read(demoControlsProvider.notifier).resetAllData();
                if (context.mounted) {
                  context.showSnackBar(context.tr('demo.data_reset_success'));
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required bool isDark,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : AppColors.textMutedLight),
              size: 20,
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
