import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../controllers/audit_logs_controller.dart';
import '../widgets/audit_log_details_dialog.dart';

/// Comprehensive HR Audit Logs & Security Accountability Screen
class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  void _showDetails(BuildContext context, AuditLogItemEntity log) {
    showDialog(
      context: context,
      builder: (ctx) => AuditLogDetailsDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuditLogsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Audit Logs & Security Trail', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Immutable, tamper-evident audit records of all administrative HR decisions and security events',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              const StatusBadge(label: 'TAMPER-EVIDENT READ-ONLY', variant: BadgeVariant.success),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Logs',
                  value: kpis != null ? '${kpis.totalLogs}' : '—',
                  subtitle: 'Audit ledger entries',
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Security Events',
                  value: kpis != null ? '${kpis.securityEvents}' : '—',
                  subtitle: 'Auth & geofence events',
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Admin Actions',
                  value: kpis != null ? '${kpis.adminActions}' : '—',
                  subtitle: 'Decisions & modifications',
                  icon: Icons.manage_accounts_outlined,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Failed Operations',
                  value: kpis != null ? '${kpis.failedOperations}' : '—',
                  subtitle: 'Rejections & blocks',
                  icon: Icons.warning_amber_outlined,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Subtabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AuditLogsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return ChoiceChip(
                label: Text(tab.label),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                onSelected: (selected) {
                  if (selected) controller.setActiveTab(tab);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Filter Bar
          FilterBar(
            searchHint: 'Search by action, actor, entity ID, or IP...',
            onSearchChanged: controller.onSearch,
            onRefresh: () => controller.fetchAuditLogs(),
            filterActions: [
              DropdownButton<AuditActionCategory?>(
                value: controller.categoryFilter,
                hint: const Text('All Categories'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...AuditActionCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))),
                ],
                onChanged: controller.onFilterCategory,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Audit Logs Data Table
          HrDataTable<AuditLogItemEntity>(
            isLoading: controller.isLoading && controller.logs.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: () => controller.fetchAuditLogs(),
            items: controller.logs,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchAuditLogs(page: page),
            onRowTap: (log) => _showDetails(context, log),
            emptyMessage: 'No audit records found matching the active filter criteria.',
            columns: [
              HrColumn<AuditLogItemEntity>(
                title: 'Timestamp',
                cellBuilder: (log) => Text(
                  DateFormatter.toDisplayDateTime(log.timestamp),
                  style: AppTypography.bodyMedium,
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'Actor (User)',
                cellBuilder: (log) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(log.actorName, style: AppTypography.bodyBold),
                    Text(log.actorRole, style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'Action Performed',
                cellBuilder: (log) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(log.action, style: AppTypography.bodyBold.copyWith(fontSize: 13)),
                    Text(log.category.label, style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'Target Entity',
                cellBuilder: (log) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${log.targetType}: ${log.targetId}', style: AppTypography.bodyMedium),
                    if (log.targetSummary != null)
                      Text(
                        log.targetSummary!,
                        style: AppTypography.captionOf(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'IP Address',
                cellBuilder: (log) => Text(log.ipAddress, style: AppTypography.body),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'Result',
                cellBuilder: (log) => StatusBadge(
                  label: log.result.label.toUpperCase(),
                  variant: _getStatusVariant(log.result),
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: 'Details',
                cellBuilder: (log) => IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'Inspect Audit Record & Metadata',
                  onPressed: () => _showDetails(context, log),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _getStatusVariant(AuditResultStatus r) {
    switch (r) {
      case AuditResultStatus.success:
        return BadgeVariant.success;
      case AuditResultStatus.warning:
        return BadgeVariant.warning;
      case AuditResultStatus.failure:
        return BadgeVariant.danger;
    }
  }
}
