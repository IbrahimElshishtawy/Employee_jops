import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/hr_request_entity.dart';
import 'request_review_dialog.dart';

/// Modal dialog for inspecting complete request details and audit history
class RequestDetailsDialog extends StatelessWidget {
  final HrRequestEntity request;
  final bool canReview;
  final Future<bool> Function({required bool approve, String? comment})? onReview;

  const RequestDetailsDialog({
    super.key,
    required this.request,
    this.canReview = false,
    this.onReview,
  });

  void _openReviewDialog(BuildContext context, bool isApproval) {
    if (onReview == null) return;

    showDialog(
      context: context,
      builder: (ctx) => RequestReviewDialog(
        request: request,
        isApproval: isApproval,
        onReview: onReview!,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req = request;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                    child: Text(
                      req.employeeName.isNotEmpty ? req.employeeName[0].toUpperCase() : 'E',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(req.employeeName, style: AppTypography.heading2),
                            const SizedBox(width: AppDimensions.space8),
                            _buildStatusBadge(req.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${req.employeeCode}${req.department != null && req.department!.isNotEmpty ? ' • ${req.department}' : ''}',
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
              const Divider(),
              const SizedBox(height: AppDimensions.space12),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text('Request Information', style: AppTypography.bodyBold),
                                  const Spacer(),
                                  _buildTypeBadge(req.type),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      context,
                                      'Requested Period',
                                      req.startDate == req.endDate
                                          ? DateFormatter.toDisplayDate(req.startDate)
                                          : '${DateFormatter.toDisplayDate(req.startDate)} → ${DateFormatter.toDisplayDate(req.endDate)}',
                                    ),
                                  ),
                                  if (req.startTime != null && req.endTime != null)
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        'Time Window',
                                        '${req.startTime} - ${req.endTime}',
                                      ),
                                    ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      context,
                                      'Submitted On',
                                      DateFormatter.toDisplayDateTime(req.createdAt),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space16),
                              Text('Employee Stated Reason:', style: AppTypography.captionOf(context)),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppDimensions.space12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Text(req.reason, style: AppTypography.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Review Outcome Card (if reviewed)
                      if (req.status != RequestStatus.pending) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      req.status == RequestStatus.approved ? Icons.verified_outlined : Icons.report_problem_outlined,
                                      size: 16,
                                      color: req.status == RequestStatus.approved ? AppColors.success : AppColors.danger,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Review Decision Outcome', style: AppTypography.bodyBold),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        'Reviewed By',
                                        req.reviewedBy ?? 'HR Administrator',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        'Review Date',
                                        req.reviewedAt != null ? DateFormatter.toDisplayDateTime(req.reviewedAt!) : '—',
                                      ),
                                    ),
                                  ],
                                ),
                                if (req.reviewComment != null && req.reviewComment!.isNotEmpty) ...[
                                  const SizedBox(height: AppDimensions.space12),
                                  Text('Reviewer Comment / Note:', style: AppTypography.captionOf(context)),
                                  const SizedBox(height: 4),
                                  Text(
                                    req.reviewComment!,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: req.status == RequestStatus.rejected ? AppColors.danger : null,
                                      fontWeight: req.status == RequestStatus.rejected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Granular History & Audit Log
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history_toggle_off_outlined, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text('Request Lifecycle & Audit Trail', style: AppTypography.bodyBold),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              if (req.history.isEmpty)
                                Text('No historical transitions recorded.', style: AppTypography.captionOf(context))
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: req.history.length,
                                  separatorBuilder: (_, _) => const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final event = req.history[index];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getActionColor(event.action).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            event.action,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getActionColor(event.action),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Actor: ${event.actor}', style: AppTypography.bodyBold),
                                                  Text(
                                                    DateFormatter.toDisplayDateTime(event.timestamp),
                                                    style: AppTypography.captionOf(context),
                                                  ),
                                                ],
                                              ),
                                              if (event.comment != null && event.comment!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(event.comment!, style: AppTypography.captionOf(context)),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (req.status == RequestStatus.pending && canReview && onReview != null) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        HrButton(
                          label: 'Reject',
                          variant: HrButtonVariant.danger,
                          icon: Icons.cancel_outlined,
                          onPressed: () => _openReviewDialog(context, false),
                        ),
                        HrButton(
                          label: 'Approve',
                          variant: HrButtonVariant.primary,
                          icon: Icons.check_circle_outline,
                          onPressed: () => _openReviewDialog(context, true),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  HrButton(
                    label: 'Close',
                    variant: HrButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      case 'CANCELLED':
        return const Color(0xFFF97316);
      case 'SUBMITTED':
      default:
        return AppColors.primaryLight;
    }
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionOf(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildTypeBadge(RequestType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Text(
        type.label,
        style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return const StatusBadge(label: 'Pending Approval', variant: BadgeVariant.warning, icon: Icons.hourglass_empty);
      case RequestStatus.approved:
        return const StatusBadge(label: 'Approved', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
      case RequestStatus.rejected:
        return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger, icon: Icons.cancel_outlined);
      case RequestStatus.cancelled:
        return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral, icon: Icons.block);
    }
  }
}
