import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
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
    final l10n = context.l10n;

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
                    Text(l10n.translate('aud_title'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('aud_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: l10n.translate('aud_tamper_evident'), variant: BadgeVariant.success),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.translate('aud_total'),
                  value: kpis != null ? l10n.formatNumber(kpis.totalLogs) : '—',
                  subtitle: l10n.translate('aud_title'),
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('aud_security_events'),
                  value: kpis != null ? l10n.formatNumber(kpis.securityEvents) : '—',
                  subtitle: l10n.translate('sec_dashboard'),
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('aud_admin_actions'),
                  value: kpis != null ? l10n.formatNumber(kpis.adminActions) : '—',
                  subtitle: l10n.translate('verified_badge'),
                  icon: Icons.manage_accounts_outlined,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('aud_failed_ops'),
                  value: kpis != null ? l10n.formatNumber(kpis.failedOperations) : '—',
                  subtitle: l10n.translate('req_status_rejected'),
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
            searchHint: l10n.translate('search_placeholder'),
            onSearchChanged: controller.onSearch,
            onRefresh: () => controller.fetchAuditLogs(),
            filterActions: [
              DropdownButton<AuditActionCategory?>(
                value: controller.categoryFilter,
                hint: Text(l10n.translate('aud_all_categories')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('aud_all_categories'))),
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
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<AuditLogItemEntity>(
                title: l10n.translate('aud_timestamp'),
                cellBuilder: (log) => Text(
                  l10n.formatDate(log.timestamp),
                  style: AppTypography.bodyMedium,
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: l10n.translate('aud_actor'),
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
                title: l10n.translate('aud_action_performed'),
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
                title: l10n.translate('aud_target_entity'),
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
                title: l10n.translate('aud_ip_address'),
                cellBuilder: (log) => Text(log.ipAddress, style: AppTypography.body),
              ),
              HrColumn<AuditLogItemEntity>(
                title: l10n.translate('aud_result'),
                cellBuilder: (log) => StatusBadge(
                  label: log.result.label.toUpperCase(),
                  variant: _getStatusVariant(log.result),
                ),
              ),
              HrColumn<AuditLogItemEntity>(
                title: l10n.translate('details'),
                cellBuilder: (log) => IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: l10n.translate('aud_inspect'),
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
