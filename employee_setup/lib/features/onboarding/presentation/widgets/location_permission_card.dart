import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

/// Explanatory card showing why GPS location access is required for attendance,
/// displaying live permission state and allow action.
class LocationPermissionCard extends ConsumerStatefulWidget {
  final bool initialGranted;

  const LocationPermissionCard({
    super.key,
    this.initialGranted = true,
  });

  @override
  ConsumerState<LocationPermissionCard> createState() =>
      _LocationPermissionCardState();
}

class _LocationPermissionCardState
    extends ConsumerState<LocationPermissionCard> {
  late bool _isGranted;

  @override
  void initState() {
    super.initState();
    _isGranted = widget.initialGranted;
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await ref.read(locationServiceProvider).requestPermission();
      if (mounted) {
        setState(() => _isGranted = granted);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGranted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_isGranted ? AppColors.success : AppColors.info)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isGranted
                      ? Icons.verified_user_rounded
                      : Icons.near_me_rounded,
                  color: _isGranted ? AppColors.success : AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('onboarding.location_access_title'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isGranted
                          ? context.tr('onboarding.location_permission_enabled')
                          : context.tr('onboarding.location_permission_required'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isGranted ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            context.tr('onboarding.location_access_desc'),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),

          if (!_isGranted)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  context.tr('onboarding.allow_location'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
