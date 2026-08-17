import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate([String? locale]) {
    return DateFormat.yMMMMd(locale ?? 'ar').format(this);
  }

  String toFormattedShortDate([String? locale]) {
    return DateFormat.yMd(locale ?? 'ar').format(this);
  }
  String toFormattedMonthYear([String? locale]) {
    return DateFormat.yMMMM(locale ?? 'ar').format(this);
  }
  String toFormattedYear([String? locale]) {
    return DateFormat.y(locale ?? 'ar').format(this);
  }

  String toFormattedTime([String? locale]) {
    return DateFormat.jm(locale ?? 'ar').format(this);
  }

  String toFormattedDateTime([String? locale]) {
    return '${toFormattedDate(locale)} - ${toFormattedTime(locale)}';
  }

  String timeAgo([String? locale]) {
    final now = DateTime.now();
    final difference = now.difference(this);

    final isAr = (locale ?? 'ar').startsWith('ar');

    if (difference.inSeconds < 60) {
      return isAr ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return isAr ? 'منذ $mins دقيقة' : '$mins min ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isAr ? 'منذ $hours ساعة' : '$hours hrs ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return isAr ? 'منذ $days يوم' : '$days days ago';
    } else {
      return toFormattedShortDate(locale);
    }
  }
}
