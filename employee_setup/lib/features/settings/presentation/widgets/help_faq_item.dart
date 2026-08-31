import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

/// Reusable expandable FAQ accordion item.
class HelpFaqItem extends StatefulWidget {
  final String category;
  final String question;
  final String answer;
  final IconData? icon;
  final Color? iconColor;
  final bool initialExpanded;

  const HelpFaqItem({
    super.key,
    required this.category,
    required this.question,
    required this.answer,
    this.icon,
    this.iconColor,
    this.initialExpanded = false,
  });

  @override
  State<HelpFaqItem> createState() => _HelpFaqItemState();
}

class _HelpFaqItemState extends State<HelpFaqItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = widget.iconColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            ),
                            child: Text(
                              widget.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.question,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Text(
                          widget.answer,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
