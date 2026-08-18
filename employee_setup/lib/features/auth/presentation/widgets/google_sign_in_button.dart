import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Premium Enterprise Google Sign-In Button with 4-color Google mark,
/// responsive states, loading animation, and accessible semantics.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final buttonLabel = label ?? context.tr('auth.continue_google');
    final loadingLabel = context.tr('auth.signing_in');

    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: isLoading ? loadingLabel : buttonLabel,
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLarge,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.2,
          ),
        ),
        elevation: isDark ? 0 : 1,
        shadowColor: const Color(0x10000000),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loadingLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 4-Color Google Logo
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CustomPaint(
                              painter: _Google4ColorLogoPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              buttonLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Official 4-Color Google 'G' Painter
class _Google4ColorLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red: Top & Upper Left (angle ~ 220 to 330 deg)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.9, true, paint);

    // Yellow: Bottom Left (angle ~ 140 to 220 deg)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.1, 1.8, true, paint);

    // Green: Bottom & Lower Right (angle ~ 40 to 140 deg)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.6, 1.6, true, paint);

    // Blue: Right & Upper Right (angle ~ -40 to 40 deg)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.6, 1.2, true, paint);

    // White Center Hole
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.58, paint);

    // Blue Crossbar
    paint.color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTRB(
      center.dx - 1,
      center.dy - radius * 0.22,
      w,
      center.dy + radius * 0.22,
    );
    canvas.drawRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
