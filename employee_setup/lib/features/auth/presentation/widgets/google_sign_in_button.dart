import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Premium Enterprise Google Sign-In Button.
/// Supports both filled primary style (as shown in reference design) and outlined style.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final bool isFilled;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label,
    this.isFilled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final buttonLabel = label ?? context.tr('auth.continue_google');
    final loadingLabel = context.tr('auth.signing_in');

    final bgColor = isFilled
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : Colors.white);
    final textColor = isFilled
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimaryLight);

    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: isLoading ? loadingLabel : buttonLabel,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isFilled
              ? BorderSide.none
              : BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.2,
                ),
        ),
        elevation: isFilled ? 1 : 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loadingLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular White Badge with 4-Color Google Logo
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: CustomPaint(
                              painter: _Google4ColorLogoPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              buttonLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                                color: textColor,
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
