import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/permission_request.dart';

class PermissionDetailsScreen extends ConsumerWidget {
  final String permissionId;

  const PermissionDetailsScreen({super.key, required this.permissionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(permissionsListProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: const AppHeader(
        title: 'تفاصيل إذن الاستئذان',
      ),
      body: Builder(
        builder: (context) {
          final list = permsAsync;
          final perm = list.isEmpty
              ? PermissionRequest(
                  id: permissionId,
                  employeeId: 'EMP-1024',
                  type: PermissionType.earlyLeave,
                  date: DateTime.now(),
                  durationOrTime: 'ساعتان',
                  reason: 'استئذان',
                  status: PermissionStatus.pending,
                  createdAt: DateTime.now(),
                )
              : list.firstWhere(
                  (e) => e.id == permissionId,
                  orElse: () => PermissionRequest(
                    id: permissionId,
                    employeeId: 'EMP-1024',
                    type: PermissionType.earlyLeave,
                    date: DateTime.now(),
                    durationOrTime: 'ساعتان',
                    reason: 'استئذان',
                    status: PermissionStatus.pending,
                    createdAt: DateTime.now(),
                  ),
                );

          BadgeStatus badge = BadgeStatus.pending;
          String label = 'قيد المراجعة';
          switch (perm.status) {
            case PermissionStatus.pending:
              badge = BadgeStatus.pending;
              label = 'قيد المراجعة';
              break;
            case PermissionStatus.approved:
              badge = BadgeStatus.approved;
              label = 'تمت الموافقة';
              break;
            case PermissionStatus.rejected:
              badge = BadgeStatus.rejected;
              label = 'مرفوض';
              break;
            case PermissionStatus.cancelled:
              badge = BadgeStatus.cancelled;
              label = 'ملغي';
              break;
          }

          String typeName = 'إذن';
          switch (perm.type) {
            case PermissionType.morningDelay:
              typeName = 'إذن تأخير صباحي';
              break;
            case PermissionType.earlyLeave:
              typeName = 'إذن انصراف مبكر';
              break;
            case PermissionType.fullDayAbsence:
              typeName = 'إذن غياب يوم';
              break;
            case PermissionType.halfDay:
              typeName = 'إذن نصف يوم عمل';
              break;
          }

          return SingleChildScrollView(
            padding: AppDimensions.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            perm.date.toFormattedDate(context.l10n.locale.languageCode),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(label: label, status: badge),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _buildInfoRow('رقم الطلب', perm.id, isDark),
                      const Divider(),
                      _buildInfoRow('الوقت / المدة', perm.durationOrTime, isDark),
                      const Divider(),
                      _buildInfoRow('سبب الاستئذان', perm.reason, isDark),
                      const Divider(),
                      _buildInfoRow('تاريخ الإنشاء', perm.createdAt.toFormattedDateTime(), isDark),
                      if (perm.approvedAt != null) ...[
                        const Divider(),
                        _buildInfoRow('تاريخ الاعتماد', perm.approvedAt!.toFormattedDateTime(), isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
