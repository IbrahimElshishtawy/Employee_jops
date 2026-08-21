import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../locale_controller.dart';

/// Global language switcher widget for switching between English and Arabic
class LanguageSwitcher extends StatelessWidget {
  final bool compact;

  const LanguageSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();
    final isArabic = localeCtrl.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return IconButton(
        tooltip: isArabic ? 'Switch to English' : 'التحويل إلى العربية',
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Text(
            isArabic ? 'EN' : 'عربي',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        onPressed: () => localeCtrl.toggleLocale(),
      );
    }

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'en',
          label: Text('English'),
          icon: Icon(Icons.language, size: 16),
        ),
        ButtonSegment(
          value: 'ar',
          label: Text('العربية'),
          icon: Icon(Icons.translate, size: 16),
        ),
      ],
      selected: {localeCtrl.languageCode},
      onSelectionChanged: (set) => localeCtrl.setLanguage(set.first),
    );
  }
}
