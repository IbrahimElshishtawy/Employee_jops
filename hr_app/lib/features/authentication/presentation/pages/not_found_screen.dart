import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/forms/hr_button.dart';

/// Screen shown for undefined routes (404)
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: const BoxDecoration(
                        color: AppColors.neutralBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off_outlined, size: 48, color: AppColors.textMutedLight),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    const Text('Page Not Found (404)', style: AppTypography.heading2),
                    const SizedBox(height: AppDimensions.space8),
                    const Text(
                      'The requested page or route does not exist in CyberWise IE HR Portal.',
                      style: AppTypography.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    HrButton(
                      label: 'Go to Dashboard',
                      icon: Icons.home_outlined,
                      onPressed: () => context.go(RouteNames.dashboard),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
