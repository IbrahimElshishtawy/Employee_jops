import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/forms/hr_button.dart';

/// Screen shown when a user accesses a route without sufficient permissions
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

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
                        color: AppColors.dangerBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_outlined, size: 48, color: AppColors.danger),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    const Text('Access Denied (403)', style: AppTypography.heading2),
                    const SizedBox(height: AppDimensions.space8),
                    const Text(
                      'Your role does not have the required permissions to view this module. Please contact your system administrator if you believe this is an error.',
                      style: AppTypography.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    HrButton(
                      label: 'Return to Dashboard',
                      icon: Icons.arrow_back,
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
