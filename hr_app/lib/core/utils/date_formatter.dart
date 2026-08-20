import 'package:intl/intl.dart';

/// Centralized date and time formatting utilities
class DateFormatter {
  DateFormatter._();

  static final DateFormat _standardDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTimeDisplay = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _timeOnly = DateFormat('HH:mm');

  static String toIsoDate(DateTime? date) {
    if (date == null) return '';
    return _standardDate.format(date);
  }

  static String toDisplayDate(DateTime? date) {
    if (date == null) return '-';
    return _displayDate.format(date);
  }

  static String toDisplayDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeDisplay.format(date);
  }

  static String toTimeOnly(DateTime? date) {
    if (date == null) return '-';
    return _timeOnly.format(date);
  }

  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }
}
