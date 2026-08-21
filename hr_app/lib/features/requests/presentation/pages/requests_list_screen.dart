import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/date_range_picker.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/hr_request_entity.dart';
import '../controllers/requests_controller.dart';
import '../widgets/request_details_dialog.dart';
import '../widgets/request_review_dialog.dart';

/// Requests Management & Approvals Screen
class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  static const List<String> kDepartments = [
    'Engineering',
    'Human Resources',
    'Operations',
    'Finance',
    'Marketing',
    'Legal',
    'Administration',
    'Information Technology',
  ];

  void _showRequestDetails(BuildContext context, HrRequestEntity request, bool canReview) {
    showDialog(
      context: context,
      builder: (ctx) => RequestDetailsDialog(
        request: request,
        canReview: canReview,
        onReview: ({required approve, comment}) async {
          return await context.read<RequestsController>().reviewRequest(
                request.id,
                approve: approve,
                comment: comment,
              );
        },
      ),
    );
  }

  void _openReviewDialog(BuildContext context, HrRequestEntity request, bool isApproval) {
    showDialog(
      context: context,
      builder: (ctx) => RequestReviewDialog(
        request: request,
        isApproval: isApproval,
        onReview: ({required approve, comment}) async {
          final success = await context.read<RequestsController>().reviewRequest(
                request.id,
                approve: approve,
                comment: comment,
              );
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isApproval
                    ? 'Request from ${request.employeeName} approved successfully.'
                    : 'Request from ${request.employeeName} rejected.'),
                backgroundColor: isApproval ? AppColors.success : AppColors.danger,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RequestsController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canApprove = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.requestsApprove);
    final canReject = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.requestsReject);
    final canReview = canApprove || canReject;

    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee Requests & Approvals', style: AppTypography.heading1),
              const SizedBox(height: 4),
              Text(
                'Review and process employee leave, permissions, late arrivals, and absence requests',
                style: AppTypography.subtitleOf(context),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending Review',
                  value: kpis != null ? '${kpis.pendingCount}' : '—',
                  subtitle: 'Action required by HR',
                  icon: Icons.hourglass_empty,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Approved',
                  value: kpis != null ? '${kpis.approvedCount}' : '—',
                  subtitle: 'Confirmed within policy',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Rejected',
                  value: kpis != null ? '${kpis.rejectedCount}' : '—',
                  subtitle: 'With formal justification',
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Cancelled',
                  value: kpis != null ? '${kpis.cancelledCount}' : '—',
                  subtitle: 'Self-cancelled by staff',
                  icon: Icons.block,
                  iconColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational Sub-tabs
          Row(
            children: RequestsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab.label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                  onSelected: (selected) {
                    if (selected) controller.setActiveTab(tab);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Filter Bar
          FilterBar(
            searchHint: 'Search employee name, code, reason...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchRequests,
            filterActions: [
              // Request Type Filter
              DropdownButton<RequestType?>(
                value: controller.typeFilter,
                hint: const Text('All Request Types'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Request Types')),
                  ...RequestType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  ),
                ],
                onChanged: controller.onFilterType,
              ),
              const SizedBox(width: 8),

              // Request Status Filter (Only active on All tab)
              if (controller.activeTab == RequestsTab.all) ...[
                DropdownButton<RequestStatus?>(
                  value: controller.statusFilter,
                  hint: const Text('All Statuses'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...RequestStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: controller.onFilterStatus,
                ),
                const SizedBox(width: 8),
              ],

              // Department Filter
              DropdownButton<String?>(
                value: controller.departmentFilter,
                hint: const Text('All Departments'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                  ...kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: controller.onFilterDepartment,
              ),
              const SizedBox(width: 8),

              // Date Range Picker
              DateRangePickerField(
                startDate: controller.dateRange?.start,
                endDate: controller.dateRange?.end,
                onRangeSelected: controller.onDateRangeSelected,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Requests Data Table
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
            onRowTap: (req) => _showRequestDetails(context, req, canReview),
            emptyMessage: 'No requests match the selected criteria.',
            columns: [
              HrColumn<HrRequestEntity>(
                title: 'Employee',
                cellBuilder: (req) => Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                      child: Text(
                        req.employeeName.isNotEmpty ? req.employeeName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(req.employeeName, style: AppTypography.bodyBold),
                        Text(
                          req.department != null && req.department!.isNotEmpty
                              ? '${req.employeeCode} • ${req.department}'
                              : req.employeeCode,
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: 'Request Type',
                cellBuilder: (req) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    req.type.label,
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: 'Period / Time',
                cellBuilder: (req) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      req.startDate == req.endDate
                          ? DateFormatter.toDisplayDate(req.startDate)
                          : '${DateFormatter.toDisplayDate(req.startDate)} → ${DateFormatter.toDisplayDate(req.endDate)}',
                      style: AppTypography.bodyBold,
                    ),
                    if (req.startTime != null && req.endTime != null)
                      Text('${req.startTime} - ${req.endTime}', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: 'Reason Justification',
                cellBuilder: (req) => SizedBox(
                  width: 200,
                  child: Text(
                    req.reason,
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: 'Submitted At',
                cellBuilder: (req) => Text(DateFormatter.toDisplayDate(req.createdAt), style: AppTypography.body),
              ),
              HrColumn<HrRequestEntity>(
                title: 'Status',
                cellBuilder: (req) {
                  switch (req.status) {
                    case RequestStatus.pending:
                      return const StatusBadge(label: 'Pending', variant: BadgeVariant.warning, icon: Icons.hourglass_empty);
                    case RequestStatus.approved:
                      return const StatusBadge(label: 'Approved', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
                    case RequestStatus.rejected:
                      return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger, icon: Icons.cancel_outlined);
                    case RequestStatus.cancelled:
                      return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral, icon: Icons.block);
                  }
                },
              ),
              HrColumn<HrRequestEntity>(
                title: 'Actions',
                cellBuilder: (req) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => _showRequestDetails(context, req, canReview),
                    ),
                    if (req.status == RequestStatus.pending && canApprove)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                        tooltip: 'Approve Request',
                        onPressed: () => _openReviewDialog(context, req, true),
                      ),
                    if (req.status == RequestStatus.pending && canReject)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                        tooltip: 'Reject Request',
                        onPressed: () => _openReviewDialog(context, req, false),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
