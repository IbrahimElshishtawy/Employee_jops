import 'package:flutter/material.dart';

/// CyberWise IE Design System Color Palette
class AppColors {
  AppColors._();

  // Primary & Accent Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Slate Navy
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFF6366F1); // Indigo

  // Neutral Background & Surface Colors (Light)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Background & Surface Colors (Dark)
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color borderDark = Color(0xFF374151);
  static const Color dividerDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBgDark = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBgDark = Color(0xFF78350F);
  static const Color danger = Color(0xFFEF4444); // Rose/Red
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBgDark = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF0EA5E9); // Sky Blue
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoBgDark = Color(0xFF0C4A6E);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralBg = Color(0xFFF3F4F6);
  static const Color neutralBgDark = Color(0xFF1F2937);

  // Sidebar Colors
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarActiveItem = Color(0xFF1E293B);

  // Dynamic Theme Helpers
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dividerDark : dividerLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMutedDark : textMutedLight;
}
