import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/audit_log_entity.dart';

/// Modal dialog for inspecting audit log security details and metadata payload
class AuditLogDetailsDialog extends StatelessWidget {
  final AuditLogItemEntity log;

  const AuditLogDetailsDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: _getResultColor(log.result).withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security, color: _getResultColor(log.result), size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Audit Security Record', style: AppTypography.heading3),
                        Text('Log ID: ${log.id} • ${DateFormatter.toDisplayDateTime(log.timestamp)}', style: AppTypography.captionOf(context)),
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
                      // Status and Action Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(
                            label: log.action,
                            variant: BadgeVariant.info,
                          ),
                          StatusBadge(
                            label: log.category.label,
                            variant: BadgeVariant.neutral,
                          ),
                          StatusBadge(
                            label: log.result.label.toUpperCase(),
                            variant: _getStatusVariant(log.result),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Summary Card
                      if (log.targetSummary != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Event Summary', style: AppTypography.captionOf(context)),
                                const SizedBox(height: 6),
                                Text(log.targetSummary!, style: AppTypography.bodyMedium),
                                if (log.reason != null && log.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Reason / Justification: ${log.reason}', style: AppTypography.captionOf(context)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Actor & Target Info Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Actor (Initiator)',
                              subtitle: log.actorName,
                              details: 'Role: ${log.actorRole} • ID: ${log.actorId}',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Target Entity',
                              subtitle: '${log.targetType}: ${log.targetId}',
                              details: 'Category: ${log.category.name}',
                              icon: Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Telemetry Network Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Network IP Address',
                              subtitle: log.ipAddress,
                              details: 'Origin verified',
                              icon: Icons.network_check,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              title: 'Client User Agent',
                              subtitle: log.userAgent ?? 'Direct API / Internal',
                              details: 'System telemetry',
                              icon: Icons.devices,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Event Payload Metadata (Safely Rendered)
                      Card(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          side: BorderSide(color: AppColors.border(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.data_object, size: 16, color: AppColors.primaryLight),
                                      const SizedBox(width: 6),
                                      Text('Event Structured Metadata Payload', style: AppTypography.captionOf(context)),
                                    ],
                                  ),
                                  const StatusBadge(label: 'IMMUTABLE', variant: BadgeVariant.neutral),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppDimensions.space12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Text(
                                  log.metadata.isEmpty
                                      ? '{\n  "status": "NO_EXTRA_METADATA"\n}'
                                      : const JsonEncoder.withIndent('  ').convert(log.metadata),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: isDark ? Colors.cyanAccent : Colors.indigo[900],
                                  ),
                                ),
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

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HrButton(
                    label: 'Close',
                    variant: HrButtonVariant.primary,
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

  Widget _buildInfoCard(BuildContext context, {required String title, required String subtitle, required String details, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: AppTypography.captionOf(context), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodyBold, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(details, style: AppTypography.captionOf(context), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Color _getResultColor(AuditResultStatus r) {
    switch (r) {
      case AuditResultStatus.success:
        return AppColors.success;
      case AuditResultStatus.warning:
        return AppColors.warning;
      case AuditResultStatus.failure:
        return AppColors.danger;
    }
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
