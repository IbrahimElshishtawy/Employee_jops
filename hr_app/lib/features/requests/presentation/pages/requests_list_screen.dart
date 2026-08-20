import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/hr_request_entity.dart';
import '../controllers/requests_controller.dart';

/// Unified Requests Management Screen
class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RequestsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filters
        FilterBar(
          searchHint: 'Search employee, reason...',
          onSearchChanged: controller.onSearch,
          onRefresh: controller.fetchRequests,
          filterActions: [
            DropdownButton<RequestType?>(
              value: controller.typeFilter,
              hint: const Text('All Types'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...RequestType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
              ],
              onChanged: controller.onFilterType,
            ),
            DropdownButton<RequestStatus?>(
              value: controller.statusFilter,
              hint: const Text('All Statuses'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ...RequestStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
              ],
              onChanged: controller.onFilterStatus,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),

        // Requests Table
        HrDataTable<HrRequestEntity>(
          isLoading: controller.isLoading && controller.requests.isEmpty,
          errorMessage: controller.errorMessage,
          onRetry: controller.fetchRequests,
          items: controller.requests,
          totalItems: controller.totalCount,
          currentPage: controller.currentPage,
          totalPages: controller.totalPages,
          pageSize: controller.pageSize,
          onPageChanged: (page) => controller.fetchRequests(page: page),
          columns: [
            HrColumn<HrRequestEntity>(
              title: 'Employee',
              cellBuilder: (req) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(req.employeeName, style: AppTypography.bodyBold),
                  Text(req.employeeCode, style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<HrRequestEntity>(
              title: 'Request Type',
              cellBuilder: (req) => Text(req.type.label, style: AppTypography.bodyMedium),
            ),
            HrColumn<HrRequestEntity>(
              title: 'Dates / Duration',
              cellBuilder: (req) => Text(
                '${DateFormatter.toDisplayDate(req.startDate)} - ${DateFormatter.toDisplayDate(req.endDate)}',
                style: AppTypography.body,
              ),
            ),
            HrColumn<HrRequestEntity>(
              title: 'Reason',
              cellBuilder: (req) => Text(
                req.reason,
                style: AppTypography.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            HrColumn<HrRequestEntity>(
              title: 'Status',
              cellBuilder: (req) {
                switch (req.status) {
                  case RequestStatus.pending:
                    return const StatusBadge(label: 'Pending', variant: BadgeVariant.warning);
                  case RequestStatus.approved:
                    return const StatusBadge(label: 'Approved', variant: BadgeVariant.success);
                  case RequestStatus.rejected:
                    return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger);
                  case RequestStatus.cancelled:
                    return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral);
                }
              },
            ),
            HrColumn<HrRequestEntity>(
              title: 'Actions',
              cellBuilder: (req) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (req.status == RequestStatus.pending) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      tooltip: 'Approve Request',
                      onPressed: () => _showReviewDialog(context, controller, req, approve: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
                      tooltip: 'Reject Request',
                      onPressed: () => _showReviewDialog(context, controller, req, approve: false),
                    ),
                  ] else
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => _showRequestDetails(context, req),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    RequestsController controller,
    HrRequestEntity req, {
    required bool approve,
  }) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve ? 'Approve Request' : 'Reject Request',
          style: AppTypography.heading3.copyWith(
            color: approve ? AppColors.success : AppColors.danger,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee: ${req.employeeName} (${req.employeeCode})', style: AppTypography.bodyBold),
              Text('Type: ${req.type.label}', style: AppTypography.body),
              Text('Reason: ${req.reason}', style: AppTypography.caption),
              const SizedBox(height: AppDimensions.space16),
              HrTextField(
                label: 'Review Notes / Comments (Optional)',
                hint: 'Enter any remarks...',
                controller: commentCtrl,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          HrButton(
            label: 'Cancel',
            variant: HrButtonVariant.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          HrButton(
            label: approve ? 'Confirm Approval' : 'Confirm Rejection',
            variant: approve ? HrButtonVariant.primary : HrButtonVariant.danger,
            onPressed: () {
              Navigator.pop(context);
              controller.reviewRequest(
                req.id,
                approve: approve,
                comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, HrRequestEntity req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Details #${req.id}', style: AppTypography.heading3),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Employee', '${req.employeeName} (${req.employeeCode})'),
              _buildRow('Type', req.type.label),
              _buildRow('Start Date', DateFormatter.toDisplayDate(req.startDate)),
              _buildRow('End Date', DateFormatter.toDisplayDate(req.endDate)),
              _buildRow('Reason', req.reason),
              _buildRow('Status', req.status.label),
              if (req.reviewedBy != null) _buildRow('Reviewed By', req.reviewedBy!),
              if (req.reviewedAt != null) _buildRow('Reviewed At', DateFormatter.toDisplayDateTime(req.reviewedAt)),
              if (req.reviewComment != null) _buildRow('Comment', req.reviewComment!),
            ],
          ),
        ),
        actions: [
          HrButton(label: 'Close', variant: HrButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTypography.bodyBold)),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}
