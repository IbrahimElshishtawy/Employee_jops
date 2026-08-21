import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../utils/date_formatter.dart';

/// Reusable Date Range Filter Trigger
class DateRangePickerField extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange?> onRangeSelected;
  final String label;

  const DateRangePickerField({
    super.key,
    this.startDate,
    this.endDate,
    required this.onRangeSelected,
    this.label = 'Date Range',
  });

  @override
  Widget build(BuildContext context) {
    final String rangeText;
    if (startDate != null && endDate != null) {
      rangeText = '${DateFormatter.toDisplayDate(startDate)} - ${DateFormatter.toDisplayDate(endDate)}';
    } else {
      rangeText = 'Select Date Range';
    }

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 1),
          initialDateRange: startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
        );
        onRangeSelected(picked);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(context)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          color: Theme.of(context).cardTheme.color,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary(context)),
            const SizedBox(width: AppDimensions.space8),
            Text(rangeText, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
