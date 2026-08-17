import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatFull(DateTime date, [String locale = 'ar']) {
    return DateFormat.yMMMMEEEEd(locale).format(date);
  }

  static String formatMedium(DateTime date, [String locale = 'ar']) {
    return DateFormat.yMMMMd(locale).format(date);
  }

  static String formatShort(DateTime date, [String locale = 'ar']) {
    return DateFormat.yMd(locale).format(date);
  }

  static String formatTime(DateTime date, [String locale = 'ar']) {
    return DateFormat.jm(locale).format(date);
  }

  static String formatHoursAndMinutes(int totalMinutes, [String locale = 'ar']) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final isAr = locale.startsWith('ar');

    if (hours > 0 && minutes > 0) {
      return isAr ? '$hours س $minutes د' : '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return isAr ? '$hours ساعات' : '${hours}h';
    } else {
      return isAr ? '$minutes دقيقة' : '${minutes}m';
    }
  }
}
