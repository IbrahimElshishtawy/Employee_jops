import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/attendance_record.dart';

/// Modal dialog for reviewing offline attendance punches (Approve / Reject with mandatory reason)
class OfflineReviewDialog extends StatefulWidget {
  final AttendanceRecord record;
  final Future<bool> Function({required bool approve, String? reason}) onReview;

  const OfflineReviewDialog({
    super.key,
    required this.record,
    required this.onReview,
  });

  @override
  State<OfflineReviewDialog> createState() => _OfflineReviewDialogState();
}

class _OfflineReviewDialogState extends State<OfflineReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rejectionReasonController = TextEditingController();
  bool _isRejecting = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onReview(approve: true);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to approve offline record.';
        });
      }
    }
  }

  Future<void> _handleReject() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onReview(
      approve: false,
      reason: _rejectionReasonController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to reject offline record.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rec = widget.record;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_sync_outlined, color: AppColors.warning, size: 22),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Review Offline Attendance Punch', style: AppTypography.heading3),
                          Text(
                            '${rec.employeeName} (${rec.employeeCode})',
                            style: AppTypography.captionOf(context),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                ],

                // Offline Punch Summary Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Punch Date & Time', DateFormatter.toDisplayDateTime(rec.checkInTime ?? rec.date)),
                      _buildSummaryRow('Recorded Workplace', rec.workplaceName),
                      _buildSummaryRow('GPS Coordinates', '${rec.checkInLat ?? "—"}, ${rec.checkInLng ?? "—"} (±${rec.checkInAccuracy ?? "0"}m)'),
                      _buildSummaryRow('Geofence Distance', '${rec.checkInDistanceMeters ?? "0"} meters from boundary'),
                      _buildSummaryRow('Mobile Device', '${rec.deviceModel ?? "Unknown Device"} (${rec.deviceOs ?? "Unknown OS"})'),
                      _buildSummaryRow('Storage Vault', 'Encrypted local device storage synced after connection'),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Rejection Reason Field (Shows only when user initiates reject)
                if (_isRejecting) ...[
                  HrTextField(
                    label: 'Mandatory Rejection Justification Reason',
                    hint: 'e.g. Punch timestamp conflict with building security camera logs',
                    controller: _rejectionReasonController,
                    maxLines: 3,
                    validator: (v) => Validator.requiredField(v, 'A justified rejection reason is mandatory'),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Actions Footer
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppDimensions.space8,
                  runSpacing: AppDimensions.space8,
                  children: [
                    HrButton(
                      label: 'Cancel',
                      variant: HrButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (!_isRejecting) ...[
                      HrButton(
                        label: 'Reject Punch',
                        variant: HrButtonVariant.danger,
                        icon: Icons.cancel_outlined,
                        onPressed: () => setState(() => _isRejecting = true),
                      ),
                      HrButton(
                        label: 'Approve Punch',
                        variant: HrButtonVariant.primary,
                        icon: Icons.check_circle_outline,
                        isLoading: _isSubmitting,
                        onPressed: _handleApprove,
                      ),
                    ] else ...[
                      HrButton(
                        label: 'Confirm Rejection',
                        variant: HrButtonVariant.danger,
                        icon: Icons.cancel,
                        isLoading: _isSubmitting,
                        onPressed: _handleReject,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.captionOf(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyBold,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
