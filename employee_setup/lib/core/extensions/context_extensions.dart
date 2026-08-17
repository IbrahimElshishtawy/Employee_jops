import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  // Localization access
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => l10n.translate(key);
  bool get isArabic => l10n.isArabic;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  // Theme access
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;

  // Media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;

  // Navigation helpers
  void showSnackBar(String message, {bool isError = false, VoidCallback? onRetry}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: onRetry != null
            ? SnackBarAction(
                label: tr('common.retry'),
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
