import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/work_schedule.dart';

/// Warning banner displayed when attempting to check out during work hours before shift end.
class EarlyLeaveWarningBanner extends StatelessWidget {
  final WorkSchedule workSchedule;
  final bool isDark;
  final bool isRtl;
  final VoidCallback onProceedAnyway;

  const EarlyLeaveWarningBanner({
    super.key,
    required this.workSchedule,
    required this.isDark,
    required this.isRtl,
    required this.onProceedAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
        borderRadius: AppDimensions.borderRadiusLarge,
        border: Border.all(
          color: isDark ? const Color(0xFFD97706) : const Color(0xFFFCD34D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRtl
                      ? 'تنبيه: انصراف أثناء ساعات العمل الرسمية'
                      : 'Warning: Early Departure During Shift Hours',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isRtl
                ? 'مواعيد عملك المعتمدة تنتهي في الساعة ${workSchedule.formattedEndTime}. تسجيل الانصراف الآن يعتبر انصرافاً مبكراً يتطلب تقديم طلب إذن خروج وموافقة المسؤول.'
                : 'Your scheduled shift ends at ${workSchedule.formattedEndTime}. Checking out now requires an approved early departure permission.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: isRtl ? 'تقديم طلب إذن خروج' : 'Request Early Leave',
                  icon: Icons.timer_outlined,
                  onPressed: () {
                    context.push('/requests/permissions/new');
                  },
                ),
              ),
              const SizedBox(width: 8),
              AppButton.secondary(
                label: isRtl ? 'متابعة على أي حال' : 'Proceed Anyway',
                onPressed: onProceedAnyway,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
