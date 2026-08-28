import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/employee_contact.dart';

class AvailabilityIndicator extends StatelessWidget {
  final EmployeeAvailability availability;
  final bool showText;
  final double dotSize;

  const AvailabilityIndicator({
    super.key,
    required this.availability,
    this.showText = true,
    this.dotSize = 10,
  });

  Color get color {
    switch (availability) {
      case EmployeeAvailability.available:
        return const Color(0xFF10B981); // Emerald Green
      case EmployeeAvailability.busy:
        return const Color(0xFFEF4444); // Red
      case EmployeeAvailability.away:
        return const Color(0xFFF59E0B); // Amber
      case EmployeeAvailability.offline:
        return const Color(0xFF94A3B8); // Slate Gray
    }
  }

  String localizedLabel(BuildContext context) {
    final isArabic = context.isArabic;
    switch (availability) {
      case EmployeeAvailability.available:
        return isArabic ? 'متاح الآن' : 'Available';
      case EmployeeAvailability.busy:
        return isArabic ? 'مشغول' : 'Busy';
      case EmployeeAvailability.away:
        return isArabic ? 'غير متواجد' : 'Away';
      case EmployeeAvailability.offline:
        return isArabic ? 'غير متصل' : 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: availability.isAvailable
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            localizedLabel(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
