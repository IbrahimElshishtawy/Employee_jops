import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_role.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

/// Settings & System Configuration Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final themeCtrl = context.watch<ThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('HR Portal Settings & Environment', style: AppTypography.heading2),
        const SizedBox(height: AppDimensions.space8),
        Text('System runtime configuration, theme preferences, and RBAC matrix.', style: AppTypography.subtitle),
        const SizedBox(height: AppDimensions.space24),

        // System Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Environment & API Endpoint', style: AppTypography.heading3),
                const SizedBox(height: AppDimensions.space16),
                _buildSettingRow('System ID', AppConfig.systemId),
                _buildSettingRow('Application Version', AppConfig.appVersion),
                _buildSettingRow('API Base URL', EnvConfig.apiBaseUrl),
                _buildSettingRow(
                  'Data Provider Mode',
                  EnvConfig.enableMockData ? 'Mock Development Data (Safe Test Values)' : 'Live Production REST API',
                  badge: EnvConfig.enableMockData
                      ? const StatusBadge(label: 'MOCK ACTIVE', variant: BadgeVariant.warning)
                      : const StatusBadge(label: 'LIVE REST API', variant: BadgeVariant.success),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space20),

        // RBAC Role Testing Switcher (Dev Mode)
        if (EnvConfig.enableMockData) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('RBAC Role Switcher (Development Testing)', style: AppTypography.heading3),
                      const SizedBox(width: 8),
                      const StatusBadge(label: 'DEV ONLY', variant: BadgeVariant.info),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Simulate different HR user roles to verify UI permission guards and route gating.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Wrap(
                    spacing: AppDimensions.space12,
                    runSpacing: AppDimensions.space12,
                    children: AppRole.values.map((role) {
                      final isSelected = authCtrl.currentRole == role;
                      return ChoiceChip(
                        label: Text(role.label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        onSelected: (_) => authCtrl.switchMockRole(role),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    'Granted Permissions for ${authCtrl.currentRole.label}:',
                    style: AppTypography.bodyBold,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AuthorizationService.getPermissionsForRole(authCtrl.currentRole).map((p) {
                      return Chip(
                        label: Text(p.key, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.neutralBg,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
        ],

        // Appearance & Theme Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance & Theme', style: AppTypography.heading3),
                const SizedBox(height: AppDimensions.space16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Color Scheme', style: AppTypography.bodyBold),
                          Text('Switch between Dark, Light, or System appearance.', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_brightness)),
                      ],
                      selected: {themeCtrl.themeMode},
                      onSelectionChanged: (set) => themeCtrl.setThemeMode(set.first),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 200, child: Text(label, style: AppTypography.bodyBold)),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
          ?badge,
        ],
      ),
    );
  }
}
