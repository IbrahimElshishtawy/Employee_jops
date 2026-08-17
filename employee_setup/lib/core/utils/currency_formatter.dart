import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, [String currency = 'ج.م', String locale = 'ar']) {
    final formatter = NumberFormat('#,##0.00', locale);
    return '${formatter.format(amount)} $currency';
  }

  static String formatShort(double amount, [String currency = 'ج.م']) {
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(amount)} $currency';
  }
}
