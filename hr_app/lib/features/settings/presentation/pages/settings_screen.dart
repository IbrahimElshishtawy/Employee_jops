import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/widgets/language_switcher.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/app_role.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/settings_entity.dart';
import '../controllers/settings_controller.dart';

/// Comprehensive System Settings & Policy Administration Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // General
  late TextEditingController _companyNameCtrl;
  late TextEditingController _supportEmailCtrl;
  late TextEditingController _timezoneCtrl;
  late TextEditingController _currencyCtrl;

  // Attendance
  late TextEditingController _gracePeriodCtrl;
  late TextEditingController _gpsAccuracyCtrl;
  late TextEditingController _maxOvertimeCtrl;
  late TextEditingController _autoCheckoutCtrl;

  // Notifications
  bool _pushEnabled = true;
  bool _emailDigestEnabled = true;
  late TextEditingController _advanceDaysCtrl;
  bool _alertSupervisorsOnLate = true;

  // Security
  late TextEditingController _sessionTimeoutCtrl;
  late TextEditingController _maxFailedLoginsCtrl;
  bool _tokenRotation = true;
  bool _tamperDetection = true;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController();
    _supportEmailCtrl = TextEditingController();
    _timezoneCtrl = TextEditingController();
    _currencyCtrl = TextEditingController();

    _gracePeriodCtrl = TextEditingController();
    _gpsAccuracyCtrl = TextEditingController();
    _maxOvertimeCtrl = TextEditingController();
    _autoCheckoutCtrl = TextEditingController();

    _advanceDaysCtrl = TextEditingController();
    _sessionTimeoutCtrl = TextEditingController();
    _maxFailedLoginsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    _timezoneCtrl.dispose();
    _currencyCtrl.dispose();

    _gracePeriodCtrl.dispose();
    _gpsAccuracyCtrl.dispose();
    _maxOvertimeCtrl.dispose();
    _autoCheckoutCtrl.dispose();

    _advanceDaysCtrl.dispose();
    _sessionTimeoutCtrl.dispose();
    _maxFailedLoginsCtrl.dispose();
    super.dispose();
  }

  void _syncFromBundle(SystemSettingsBundle bundle) {
    if (_isInitialized) return;
    _isInitialized = true;

    _companyNameCtrl.text = bundle.company.companyName;
    _supportEmailCtrl.text = bundle.company.supportEmail;
    _timezoneCtrl.text = bundle.company.timezone;
    _currencyCtrl.text = bundle.company.currency;

    _gracePeriodCtrl.text = '${bundle.attendance.defaultGracePeriodMinutes}';
    _gpsAccuracyCtrl.text = '${bundle.attendance.maxGpsAccuracyMeters}';
    _maxOvertimeCtrl.text = '${bundle.attendance.maxDailyOvertimeHours}';
    _autoCheckoutCtrl.text = '${bundle.attendance.autoCheckoutBufferHours}';

    _pushEnabled = bundle.notifications.pushNotificationsEnabled;
    _emailDigestEnabled = bundle.notifications.emailDigestEnabled;
    _advanceDaysCtrl.text = '${bundle.notifications.advanceAlertThresholdDays}';
    _alertSupervisorsOnLate = bundle.notifications.alertSupervisorsOnLateArrival;

    _sessionTimeoutCtrl.text = '${bundle.security.sessionTimeoutMinutes}';
    _maxFailedLoginsCtrl.text = '${bundle.security.maxFailedLoginAttempts}';
    _tokenRotation = bundle.security.refreshTokenRotationEnabled;
    _tamperDetection = bundle.security.geofenceTamperDetectionEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final authCtrl = context.watch<AuthController>();
    final themeCtrl = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canManage = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.settingsManage);

    if (controller.settings != null) {
      _syncFromBundle(controller.settings!);
    }
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('set_title'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('set_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: canManage ? (l10n.isArabic ? 'إدارة الإعدادات' : 'SETTINGS ADMIN') : (l10n.isArabic ? 'للقراءة فقط' : 'READ ONLY'),
                variant: canManage ? BadgeVariant.success : BadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Feedback Notifications
          if (controller.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.successBgDark : AppColors.successBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(controller.successMessage!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
          ],

          if (controller.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(controller.errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
          ],

          // Navigation Subtabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SettingsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return ChoiceChip(
                label: Text(tab.label),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                onSelected: (selected) {
                  if (selected) controller.setActiveTab(tab);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space20),

          // Active Tab Content
          if (controller.isLoading && controller.settings == null)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else
            _buildTabContent(context, controller, authCtrl, themeCtrl, canManage, isDark),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    SettingsController controller,
    AuthController authCtrl,
    ThemeController themeCtrl,
    bool canManage,
    bool isDark,
  ) {
    switch (controller.activeTab) {
      case SettingsTab.general:
        return _buildGeneralTab(context, controller, canManage);
      case SettingsTab.attendance:
        return _buildAttendanceTab(context, controller, canManage);
      case SettingsTab.notifications:
        return _buildNotificationsTab(context, controller, canManage);
      case SettingsTab.security:
        return _buildSecurityTab(context, controller, canManage);
      case SettingsTab.appearance:
        return _buildAppearanceTab(context, themeCtrl, isDark);
      case SettingsTab.rbac:
        return _buildRbacTab(context, authCtrl, isDark);
    }
  }

  // 1. General & Organization
  Widget _buildGeneralTab(BuildContext context, SettingsController controller, bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company & Organization Information', style: AppTypography.heading3),
            const SizedBox(height: 8),
            Text('Core corporate identity and fiscal calendar settings.', style: AppTypography.captionOf(context)),
            const SizedBox(height: AppDimensions.space20),
            Row(
              children: [
                Expanded(
                  child: HrTextField(
                    label: 'Company Name',
                    controller: _companyNameCtrl,
                    readOnly: !canManage,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: HrTextField(
                    label: 'HR Support Email',
                    controller: _supportEmailCtrl,
                    readOnly: !canManage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                Expanded(
                  child: HrTextField(
                    label: 'Operating Timezone',
                    controller: _timezoneCtrl,
                    readOnly: !canManage,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: HrTextField(
                    label: 'Payroll Currency',
                    controller: _currencyCtrl,
                    readOnly: !canManage,
                  ),
                ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(height: AppDimensions.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Save Company Settings',
                    variant: HrButtonVariant.primary,
                    icon: Icons.save_outlined,
                    isLoading: controller.isSaving,
                    onPressed: () {
                      final updated = CompanySettingsEntity(
                        companyName: _companyNameCtrl.text.trim(),
                        supportEmail: _supportEmailCtrl.text.trim(),
                        timezone: _timezoneCtrl.text.trim(),
                        currency: _currencyCtrl.text.trim(),
                        fiscalYearStart: 'January 1',
                      );
                      controller.saveCompanySettings(updated);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 2. Attendance Policy
  Widget _buildAttendanceTab(BuildContext context, SettingsController controller, bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Global Attendance Policy & Geofence Defaults', style: AppTypography.heading3),
            const SizedBox(height: 8),
            Text('System-wide punch rules, telemetry accuracy thresholds, and shift buffers.', style: AppTypography.captionOf(context)),
            const SizedBox(height: AppDimensions.space20),
            Row(
              children: [
                Expanded(
                  child: HrTextField(
                    label: 'Default Grace Period (Minutes)',
                    controller: _gracePeriodCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: HrTextField(
                    label: 'Max GPS Accuracy Threshold (Meters)',
                    controller: _gpsAccuracyCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                Expanded(
                  child: HrTextField(
                    label: 'Max Daily Overtime Cap (Hours)',
                    controller: _maxOvertimeCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: HrTextField(
                    label: 'Auto-Checkout Buffer (Hours after Shift)',
                    controller: _autoCheckoutCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(height: AppDimensions.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Save Attendance Policy',
                    variant: HrButtonVariant.primary,
                    icon: Icons.save_outlined,
                    isLoading: controller.isSaving,
                    onPressed: () {
                      final updated = AttendancePolicySettingsEntity(
                        defaultGracePeriodMinutes: int.tryParse(_gracePeriodCtrl.text) ?? 15,
                        maxGpsAccuracyMeters: int.tryParse(_gpsAccuracyCtrl.text) ?? 50,
                        maxDailyOvertimeHours: double.tryParse(_maxOvertimeCtrl.text) ?? 4.0,
                        autoCheckoutBufferHours: int.tryParse(_autoCheckoutCtrl.text) ?? 2,
                      );
                      controller.saveAttendancePolicy(updated);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 3. Notification Settings
  Widget _buildNotificationsTab(BuildContext context, SettingsController controller, bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Notification Rules & Push Channels', style: AppTypography.heading3),
            const SizedBox(height: 8),
            Text('Configure automated alert dispatching and employee push notification channels.', style: AppTypography.captionOf(context)),
            const SizedBox(height: AppDimensions.space20),
            SwitchListTile(
              title: const Text('FCM Mobile Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Deliver instant real-time alerts to employee mobile devices.', style: AppTypography.captionOf(context)),
              value: _pushEnabled,
              activeThumbColor: AppColors.primaryLight,
              onChanged: canManage ? (v) => setState(() => _pushEnabled = v) : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Email Digest & Activity Reports', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Send periodic executive summaries to management emails.', style: AppTypography.captionOf(context)),
              value: _emailDigestEnabled,
              activeThumbColor: AppColors.primaryLight,
              onChanged: canManage ? (v) => setState(() => _emailDigestEnabled = v) : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Tardiness Alert Escalation', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Notify direct supervisors upon 3 consecutive late arrivals.', style: AppTypography.captionOf(context)),
              value: _alertSupervisorsOnLate,
              activeThumbColor: AppColors.primaryLight,
              onChanged: canManage ? (v) => setState(() => _alertSupervisorsOnLate = v) : null,
            ),
            const SizedBox(height: AppDimensions.space16),
            SizedBox(
              width: 320,
              child: HrTextField(
                label: 'Advance Notice Window (Days before shift)',
                controller: _advanceDaysCtrl,
                keyboardType: TextInputType.number,
                readOnly: !canManage,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppDimensions.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Save Notification Rules',
                    variant: HrButtonVariant.primary,
                    icon: Icons.save_outlined,
                    isLoading: controller.isSaving,
                    onPressed: () {
                      final updated = NotificationSettingsEntity(
                        pushNotificationsEnabled: _pushEnabled,
                        emailDigestEnabled: _emailDigestEnabled,
                        advanceAlertThresholdDays: int.tryParse(_advanceDaysCtrl.text) ?? 3,
                        alertSupervisorsOnLateArrival: _alertSupervisorsOnLate,
                      );
                      controller.saveNotificationSettings(updated);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. Security & Sessions
  Widget _buildSecurityTab(BuildContext context, SettingsController controller, bool canManage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Security, Token Policies & Session Controls', style: AppTypography.heading3),
                const SizedBox(width: 8),
                const StatusBadge(label: 'HIGH PRIVILEGE', variant: BadgeVariant.danger),
              ],
            ),
            const SizedBox(height: 8),
            Text('Session timeouts, brute-force mitigation, and token family replay safeguards.', style: AppTypography.captionOf(context)),
            const SizedBox(height: AppDimensions.space20),
            Row(
              children: [
                Expanded(
                  child: HrTextField(
                    label: 'Session Idle Timeout (Minutes)',
                    controller: _sessionTimeoutCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: HrTextField(
                    label: 'Max Failed Login Attempts before Lockout',
                    controller: _maxFailedLoginsCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: !canManage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            SwitchListTile(
              title: const Text('Refresh Token Family Rotation (RTR)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Invalidates the entire token lineage if a used refresh token is replayed.', style: AppTypography.captionOf(context)),
              value: _tokenRotation,
              activeThumbColor: AppColors.primaryLight,
              onChanged: canManage ? (v) => setState(() => _tokenRotation = v) : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Mock Location & Geofence Tamper Detection', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Reject attendance records with mock GPS flags or spoofed altitude telemetry.', style: AppTypography.captionOf(context)),
              value: _tamperDetection,
              activeThumbColor: AppColors.primaryLight,
              onChanged: canManage ? (v) => setState(() => _tamperDetection = v) : null,
            ),
            if (canManage) ...[
              const SizedBox(height: AppDimensions.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Save Security Parameters',
                    variant: HrButtonVariant.primary,
                    icon: Icons.shield_outlined,
                    isLoading: controller.isSaving,
                    onPressed: () {
                      final updated = SecuritySettingsEntity(
                        sessionTimeoutMinutes: int.tryParse(_sessionTimeoutCtrl.text) ?? 60,
                        maxFailedLoginAttempts: int.tryParse(_maxFailedLoginsCtrl.text) ?? 5,
                        refreshTokenRotationEnabled: _tokenRotation,
                        geofenceTamperDetectionEnabled: _tamperDetection,
                      );
                      controller.saveSecuritySettings(updated);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5. Appearance & Theme
  Widget _buildAppearanceTab(BuildContext context, ThemeController themeCtrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appearance & Theme Preferences', style: AppTypography.heading3),
                const SizedBox(height: 8),
                Text('Customize the CyberWise visual presentation mode.', style: AppTypography.captionOf(context)),
                const SizedBox(height: AppDimensions.space20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Portal Color Scheme', style: AppTypography.bodyBold),
                          Text('Select your preferred interface appearance theme.', style: AppTypography.captionOf(context)),
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
                const SizedBox(height: AppDimensions.space20),
                const Divider(),
                const SizedBox(height: AppDimensions.space16),

                // Language & Regional Preference
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dashboard Language & Regional Format', style: AppTypography.bodyBold),
                          Text('Switch between English (LTR) and العربية (RTL).', style: AppTypography.captionOf(context)),
                        ],
                      ),
                    ),
                    const LanguageSwitcher(compact: false),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space20),

        // System Environment Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Runtime Environment', style: AppTypography.heading3),
                const SizedBox(height: AppDimensions.space16),
                _buildInfoRow('System ID', AppConfig.systemId),
                _buildInfoRow('App Version', AppConfig.appVersion),
                _buildInfoRow('API Endpoint', EnvConfig.apiBaseUrl),
                _buildInfoRow(
                  'Data Engine Mode',
                  EnvConfig.enableMockData ? 'Mock Development Data (Local)' : 'Production REST API',
                  badge: EnvConfig.enableMockData
                      ? const StatusBadge(label: 'MOCK ACTIVE', variant: BadgeVariant.warning)
                      : const StatusBadge(label: 'LIVE REST API', variant: BadgeVariant.success),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 6. RBAC Role Matrix (Dev Testing)
  Widget _buildRbacTab(BuildContext context, AuthController authCtrl, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Role-Based Access Control (RBAC) Matrix', style: AppTypography.heading3),
                const SizedBox(width: 8),
                const StatusBadge(label: 'DEV SIMULATOR', variant: BadgeVariant.info),
              ],
            ),
            const SizedBox(height: 8),
            Text('Simulate role switching to verify permission enforcement across the HR dashboard.', style: AppTypography.captionOf(context)),
            const SizedBox(height: AppDimensions.space20),
            Wrap(
              spacing: AppDimensions.space12,
              runSpacing: AppDimensions.space12,
              children: AppRole.values.map((role) {
                final isSelected = authCtrl.currentRole == role;
                return ChoiceChip(
                  label: Text(role.label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.2),
                  onSelected: (_) => authCtrl.switchMockRole(role),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.space20),
            Text('Granted Permissions for ${authCtrl.currentRole.label}:', style: AppTypography.bodyBold),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AuthorizationService.getPermissionsForRole(authCtrl.currentRole).map((p) {
                return Chip(
                  label: Text(p.key, style: const TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? AppColors.surfaceDark : AppColors.neutralBg,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? badge}) {
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
