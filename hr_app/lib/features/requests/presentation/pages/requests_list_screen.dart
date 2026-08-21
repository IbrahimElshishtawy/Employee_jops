import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
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

    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('req_title'), style: AppTypography.heading1),
              const SizedBox(height: 4),
              Text(
                l10n.translate('req_subtitle'),
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
                  title: l10n.translate('req_status_pending'),
                  value: kpis != null ? l10n.formatNumber(kpis.pendingCount) : '—',
                  subtitle: l10n.translate('dash_requires_action'),
                  icon: Icons.hourglass_empty,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('req_status_approved'),
                  value: kpis != null ? l10n.formatNumber(kpis.approvedCount) : '—',
                  subtitle: l10n.translate('verified_badge'),
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('req_status_rejected'),
                  value: kpis != null ? l10n.formatNumber(kpis.rejectedCount) : '—',
                  subtitle: l10n.translate('req_reason_just'),
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('req_status_cancelled'),
                  value: kpis != null ? l10n.formatNumber(kpis.cancelledCount) : '—',
                  subtitle: l10n.translate('req_status_cancelled'),
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
            searchHint: l10n.translate('search_placeholder'),
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchRequests,
            filterActions: [
              // Request Type Filter
              DropdownButton<RequestType?>(
                value: controller.typeFilter,
                hint: Text(l10n.translate('req_all_types')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('req_all_types'))),
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
                  hint: Text(l10n.translate('emp_all_statuses')),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_statuses'))),
                    ...RequestStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(l10n.translateStatus(s.name))),
                    ),
                  ],
                  onChanged: controller.onFilterStatus,
                ),
                const SizedBox(width: 8),
              ],

              // Department Filter
              DropdownButton<String?>(
                value: controller.departmentFilter,
                hint: Text(l10n.translate('emp_all_departments')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_departments'))),
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
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<HrRequestEntity>(
                title: l10n.translate('emp_name'),
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
                          recDepartmentText(req),
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: l10n.translate('req_title'),
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
                title: l10n.translate('req_period_time'),
                cellBuilder: (req) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      req.startDate == req.endDate
                          ? l10n.formatDate(req.startDate)
                          : '${l10n.formatDate(req.startDate)} → ${l10n.formatDate(req.endDate)}',
                      style: AppTypography.bodyBold,
                    ),
                    if (req.startTime != null && req.endTime != null)
                      Text('${req.startTime} - ${req.endTime}', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<HrRequestEntity>(
                title: l10n.translate('req_reason_just'),
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
                title: l10n.translate('req_submitted_at'),
                cellBuilder: (req) => Text(l10n.formatDate(req.createdAt), style: AppTypography.body),
              ),
              HrColumn<HrRequestEntity>(
                title: l10n.translate('status'),
                cellBuilder: (req) {
                  switch (req.status) {
                    case RequestStatus.pending:
                      return StatusBadge(label: l10n.translateStatus(req.status.name), variant: BadgeVariant.warning, icon: Icons.hourglass_empty);
                    case RequestStatus.approved:
                      return StatusBadge(label: l10n.translateStatus(req.status.name), variant: BadgeVariant.success, icon: Icons.check_circle_outline);
                    case RequestStatus.rejected:
                      return StatusBadge(label: l10n.translateStatus(req.status.name), variant: BadgeVariant.danger, icon: Icons.cancel_outlined);
                    case RequestStatus.cancelled:
                      return StatusBadge(label: l10n.translateStatus(req.status.name), variant: BadgeVariant.neutral, icon: Icons.block);
                  }
                },
              ),
              HrColumn<HrRequestEntity>(
                title: l10n.translate('actions'),
                cellBuilder: (req) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: l10n.translate('details'),
                      onPressed: () => _showRequestDetails(context, req, canReview),
                    ),
                    if (req.status == RequestStatus.pending && canApprove)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                        tooltip: l10n.translate('req_approve_btn'),
                        onPressed: () => _openReviewDialog(context, req, true),
                      ),
                    if (req.status == RequestStatus.pending && canReject)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                        tooltip: l10n.translate('req_reject_btn'),
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

  static String recDepartmentText(HrRequestEntity req) {
    if (req.department != null && req.department!.isNotEmpty) {
      return '${req.employeeCode} • ${req.department}';
    }
    return req.employeeCode;
  }
}
