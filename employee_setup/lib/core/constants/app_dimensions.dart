import 'package:flutter/material.dart';

/// Standard spacing, radius, padding and elevation tokens.
class AppDimensions {
  AppDimensions._();

  // Spacing
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 20.0;
  static const double radiusPill = 999.0;

  // Border Radii objects
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusExtraLarge = BorderRadius.circular(radiusExtraLarge);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Card & Button heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double inputHeight = 52.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double avatarSizeSmall = 36.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 72.0;

  // Page Padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12.0);
}
