import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_logo.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;

      setState(() => _isSigningIn = false);

      if (success) {
        final employee = ref.read(authProvider).employee;
        if (employee != null && employee.onboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/onboarding/personal');
        }
      } else {
        setState(() {
          _errorMessage = context.tr('auth.error_generic');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _errorMessage = context.tr('auth.error_generic');
      });
    }
  }

  void _toggleLanguage() {
    final currentLocale = ref.read(settingsProvider).locale;
    final newLocale = currentLocale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    ref.read(settingsProvider.notifier).setLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final currentLocale = ref.watch(settingsProvider).locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 1. Top Header: Logo + Live Language Switcher ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Identity Badge
                      Row(
                        children: [
                          const AppLogo(
                            size: 38,
                            iconSize: 20,
                            borderRadius: 10,
                            showShadow: true,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRtl ? 'منظومة الموظف' : 'Employee Hub',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isRtl
                                    ? 'الإصدار المؤسسي v2.4'
                                    : 'Enterprise Edition v2.4',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Language Switcher Pill
                      InkWell(
                        onTap: _toggleLanguage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.language_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'English' : 'العربية',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── 2. Title & Subtitle ────────────────────────────
                  Text(
                    context.tr('auth.welcome_back'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRtl
                        ? 'شجرة الملفات والويدجيت المترابطة بالمنظومة'
                        : 'Integrated Application File & Widget Tree',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 3. Widget & File Hierarchy Tree ────────────────
                  _buildWidgetFileTree(isDark, isRtl),
                  const SizedBox(height: 20),

                  // Inline Error Banner
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(isDark),
                    const SizedBox(height: 16),
                  ],

                  // ─── 4. Google Sign-In Action Card ──────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GoogleSignInButton(
                          isLoading: _isSigningIn,
                          onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isRtl
                              ? 'دخول موحد معتمد عبر حساب Google المؤسسي'
                              : 'Authorized SSO with Corporate Google Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMutedDark
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 5. Security & Governance Seal ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('auth.secure_access'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRtl
                        ? 'تشفير 256-bit SSL • حوكمة رقمية متوافقة'
                        : '256-bit SSL Encrypted • Enterprise Compliance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textMutedDark
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the complete hierarchical File & Widget Tree
  Widget _buildWidgetFileTree(bool isDark, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Root Directory Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'lib/features_tree/',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRtl ? 'متصل بالخادم' : 'Live Sync',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Tree Branches / Nodes ──
          // Branch 1: Auth & Identity
          _buildTreeBranch(
            folderName: 'auth/',
            folderLabel: isRtl ? 'المصادقة والأمان' : 'Auth & Security',
            color: const Color(0xFF2563EB),
            files: [
              _TreeFile(
                name: 'google_sso_service.dart',
                tag: isRtl ? 'توثيق آمن' : 'OAuth 2.0',
                icon: Icons.vpn_key_outlined,
              ),
              _TreeFile(
                name: 'employee_session.dart',
                tag: isRtl ? 'جلسة مشفّرة' : 'Encrypted',
                icon: Icons.shield_outlined,
              ),
            ],
            isDark: isDark,
            isRtl: isRtl,
          ),
          const SizedBox(height: 10),

          // Branch 2: Attendance & Geofencing
          _buildTreeBranch(
            folderName: 'attendance/',
            folderLabel: isRtl ? 'الحضور ونطاق 4m' : 'Smart GPS & 4m',
            color: const Color(0xFF059669),
            files: [
              _TreeFile(
                name: 'geofence_4m_verifier.dart',
                tag: isRtl ? 'نطاق دقيق 4m' : '4-Meter Radius',
                icon: Icons.location_on_outlined,
              ),
              _TreeFile(
                name: 'biometric_auth_node.dart',
                tag: isRtl ? 'بصمة حيوية' : 'Biometrics',
                icon: Icons.fingerprint_rounded,
              ),
            ],
            isDark: isDark,
            isRtl: isRtl,
          ),
          const SizedBox(height: 10),

          // Branch 3: Requests & Operations
          _buildTreeBranch(
            folderName: 'requests_and_hub/',
            folderLabel: isRtl ? 'الطلبات والعمليات' : 'Workflow & Leaves',
            color: const Color(0xFF7C3AED),
            files: [
              _TreeFile(
                name: 'vacation_leaves_flow.dart',
                tag: isRtl ? 'إجازات وموافقات' : 'Approvals',
                icon: Icons.event_note_outlined,
              ),
              _TreeFile(
                name: 'advances_finance_hub.dart',
                tag: isRtl ? 'سُلف ومصروفات' : 'Finance Node',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
            isDark: isDark,
            isRtl: isRtl,
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Single Folder Branch in the Tree
  Widget _buildTreeBranch({
    required String folderName,
    required String folderLabel,
    required Color color,
    required List<_TreeFile> files,
    required bool isDark,
    required bool isRtl,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 6, right: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch Folder Header
          Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                folderName,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '($folderLabel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMutedDark
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // File Nodes inside this Folder
          ...files.map((file) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
              child: Row(
                children: [
                  Text(
                    isRtl ? '├─ ' : '├── ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Icon(
                    file.icon,
                    size: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      file.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      file.tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Error Banner
  Widget _buildErrorBanner(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : AppColors.errorLight,
        borderRadius: AppDimensions.borderRadiusMedium,
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeFile {
  final String name;
  final String tag;
  final IconData icon;

  const _TreeFile({
    required this.name,
    required this.tag,
    required this.icon,
  });
}
