import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/hr_request_entity.dart';

/// Modal dialog for reviewing an employee request (Approve confirmation or Reject with mandatory reason)
class RequestReviewDialog extends StatefulWidget {
  final HrRequestEntity request;
  final bool isApproval;
  final Future<bool> Function({required bool approve, String? comment}) onReview;

  const RequestReviewDialog({
    super.key,
    required this.request,
    required this.isApproval,
    required this.onReview,
  });

  @override
  State<RequestReviewDialog> createState() => _RequestReviewDialogState();
}

class _RequestReviewDialogState extends State<RequestReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!widget.isApproval) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onReview(
      approve: widget.isApproval,
      comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = widget.isApproval ? 'Unable to approve this request.' : 'Unable to reject this request.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req = widget.request;
    final isApproval = widget.isApproval;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                        color: (isApproval ? AppColors.success : AppColors.danger).withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproval ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: isApproval ? AppColors.success : AppColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproval ? 'Approve Request' : 'Reject Request',
                            style: AppTypography.heading3,
                          ),
                          Text(
                            '${req.employeeName} (${req.employeeCode}) • ${req.type.label}',
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

                // Request Summary Box
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason provided by employee:', style: AppTypography.captionOf(context)),
                      const SizedBox(height: 4),
                      Text(req.reason, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Comment or Mandatory Reason
                if (!isApproval) ...[
                  HrTextField(
                    label: 'Mandatory Rejection Reason',
                    hint: 'Explain why this request cannot be approved at this time...',
                    controller: _commentController,
                    maxLines: 3,
                    validator: (v) => Validator.requiredField(v, 'A justified rejection reason is mandatory'),
                  ),
                ] else ...[
                  HrTextField(
                    label: 'Optional Approval Note / Comment',
                    hint: 'e.g. Approved within standard team quota allowance',
                    controller: _commentController,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppDimensions.space20),

                // Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HrButton(
                      label: 'Cancel',
                      variant: HrButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    HrButton(
                      label: isApproval ? 'Confirm Approval' : 'Confirm Rejection',
                      variant: isApproval ? HrButtonVariant.primary : HrButtonVariant.danger,
                      icon: isApproval ? Icons.check : Icons.cancel,
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
