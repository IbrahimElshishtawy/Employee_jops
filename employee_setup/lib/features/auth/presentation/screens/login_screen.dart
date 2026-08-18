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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSigningIn = false;
  String? _errorMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ─── 1. Background Ambient Lighting & Network Dots ───────────
          Positioned.fill(
            child: CustomPaint(
              painter: _NetworkGridBackgroundPainter(
                isDark: isDark,
                animationValue: _animController,
              ),
            ),
          ),

          // ─── 2. Main Scrollable Content ──────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      // Top Enterprise Badge
                      _buildTopPillBadge(isDark, isRtl),
                      const SizedBox(height: 18),

                      // Main Title & Subtitle
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
                            ? 'شبكة متكاملة تربط جميع خدمات وملفات الموظف'
                            : 'An integrated network linking all employee services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── 3. Interconnected Modules Network Graph ────
                      _buildConnectedModulesNetwork(isDark, isRtl),
                      const SizedBox(height: 24),

                      // Inline Error Banner (if any)
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(isDark),
                        const SizedBox(height: 16),
                      ],

                      // ─── 4. Login Action Card ────────────────────────
                      _buildLoginCard(isDark, isRtl),
                      const SizedBox(height: 20),

                      // ─── 5. Security & Trust Footer ──────────────────
                      _buildSecurityFooter(isDark, isRtl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Enterprise Pill
  Widget _buildTopPillBadge(bool isDark, bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (_, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(
                        alpha: 0.4 + 0.4 * _animController.value,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isRtl
                  ? 'منظومة الموظفين الرقمية المترابطة'
                  : 'Connected Enterprise Employee Network',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Interconnected Modules Network Graph
  Widget _buildConnectedModulesNetwork(bool isDark, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Top Two Connected Nodes
          Row(
            children: [
              Expanded(
                child: _buildNetworkNode(
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF3B82F6),
                  title: isRtl ? 'الهوية الرقمية' : 'Digital ID',
                  subtitle: isRtl ? 'ملف الموظف' : 'Profile Node',
                  status: isRtl ? 'نشط' : 'Active',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNetworkNode(
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF10B981),
                  title: isRtl ? 'الحضور الذكي' : 'GPS Attendance',
                  subtitle: isRtl ? 'نطاق 4 أمتار' : 'Geofence Node',
                  status: isRtl ? 'مربوط' : 'Linked',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Center Connecting Core
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(
                  size: 32,
                  iconSize: 18,
                  borderRadius: 8,
                  showShadow: false,
                ),
                const SizedBox(width: 10),
                Text(
                  isRtl
                      ? 'المركز الرئيسي لمعالجة البيانات والطلبات'
                      : 'Central Data & Request Processing Hub',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.sync_alt_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Bottom Two Connected Nodes
          Row(
            children: [
              Expanded(
                child: _buildNetworkNode(
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF8B5CF6),
                  title: isRtl ? 'مركز الطلبات' : 'Requests Hub',
                  subtitle: isRtl ? 'إجازات واستئذان' : 'Approvals',
                  status: isRtl ? 'مربوط' : 'Linked',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNetworkNode(
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFF59E0B),
                  title: isRtl ? 'السُلف والمصروفات' : 'Finance & Advances',
                  subtitle: isRtl ? 'تقارير مالية' : 'Expense Node',
                  status: isRtl ? 'مربوط' : 'Linked',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Single Module Node in the Grid
  Widget _buildNetworkNode({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String status,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark.withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                      status,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textMutedDark
                  : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Login Card
  Widget _buildLoginCard(bool isDark, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GoogleSignInButton(
            isLoading: _isSigningIn,
            onPressed: _isSigningIn ? null : _handleGoogleSignIn,
          ),
          const SizedBox(height: 12),
          Text(
            isRtl
                ? 'تسجيل دخول موحد عبر Google المؤسسي المعتمد'
                : 'Single Sign-On with Authorized Enterprise Google',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
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

  /// Security Footer
  Widget _buildSecurityFooter(bool isDark, bool isRtl) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
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
        const SizedBox(height: 6),
        Text(
          isRtl
              ? 'تشفير 256-bit SSL • مطابقة لسياسات الأمان والحوكمة المؤسسية'
              : '256-bit SSL Encrypted • Enterprise Compliance & Policy Protected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}

/// Custom Background Painter drawing subtle interconnected grid pattern
class _NetworkGridBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animationValue;

  _NetworkGridBackgroundPainter({
    required this.isDark,
    required this.animationValue,
  }) : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
          .withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const double step = 36.0;

    // Draw subtle grid lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw subtle glowing nodes at intersections
    final dotPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.fill;

    for (double x = step; x < size.width; x += step * 3) {
      for (double y = step; y < size.height; y += step * 3) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkGridBackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
