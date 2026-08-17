import 'package:flutter/material.dart';

/// Centralized color palette following Material 3 and enterprise standards.
/// - Primary: #1A73E8
/// - Surface & Backgrounds: Clean, soft grays, whites
/// - Status colors: semantic Success, Warning, Error, Info
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primaryDark = Color(0xFF1557B0);

  // Background & Surface Colors (Light)
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F4F9);

  // Background & Surface Colors (Dark)
  static const Color backgroundDark = Color(0xFF121417);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color surfaceVariantDark = Color(0xFF282C34);

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF333842);
  static const Color dividerLight = Color(0xFFEEF2F6);
  static const Color dividerDark = Color(0xFF2D3139);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // Semantic / Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoDark = Color(0xFF1D4ED8);

  // Neutral Accents
  static const Color cardShadow = Color(0x0A000000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
