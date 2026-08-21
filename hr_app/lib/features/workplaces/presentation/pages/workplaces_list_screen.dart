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
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/workplace_entity.dart';
import '../../domain/utils/geofence_math.dart';
import '../controllers/workplace_controller.dart';
import '../widgets/workplace_assign_staff_dialog.dart';
import '../widgets/workplace_boundary_preview_widget.dart';
import '../widgets/workplace_form_dialog.dart';

/// Workplaces & Polygon Geofence Management Screen
class WorkplacesListScreen extends StatefulWidget {
  const WorkplacesListScreen({super.key});

  @override
  State<WorkplacesListScreen> createState() => _WorkplacesListScreenState();
}

class _WorkplacesListScreenState extends State<WorkplacesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkplaceController>().fetchWorkplaces();
    });
  }

  void _openCreateDialog(BuildContext context, WorkplaceController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkplaceFormDialog(
        onSave: (newWp) => controller.createWorkplace(newWp),
      ),
    );
  }

  void _openEditDialog(BuildContext context, WorkplaceEntity wp, WorkplaceController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkplaceFormDialog(
        workplace: wp,
        onSave: (updatedWp) => controller.updateWorkplace(updatedWp),
      ),
    );
  }

  void _openPreviewDialog(BuildContext context, WorkplaceEntity wp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              wp.geofenceType == GeofenceType.polygon ? Icons.polyline_outlined : Icons.circle_outlined,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 8),
            Text('${wp.name} Boundary Preview', style: AppTypography.heading3),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: WorkplaceBoundaryPreviewWidget(workplace: wp),
        ),
        actions: [
          HrButton(
            label: 'Close',
            variant: HrButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _openAssignStaffDialog(BuildContext context, WorkplaceEntity wp, WorkplaceController controller) {
    showDialog(
      context: context,
      builder: (context) => WorkplaceAssignStaffDialog(
        workplace: wp,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkplaceController>();
    final authCtrl = context.watch<AuthController>();
    final canCreate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.workplacesCreate);
    final canUpdate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.workplacesUpdate);

    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Stat Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.translate('wp_total'),
                  value: l10n.formatNumber(controller.totalCount),
                  icon: Icons.business_outlined,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: StatCard(
                  title: l10n.translate('wp_active_geofences'),
                  value: l10n.formatNumber(controller.activeGeofenceCount),
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: StatCard(
                  title: l10n.translate('wp_polygon_boundaries'),
                  value: l10n.formatNumber(controller.polygonCount),
                  icon: Icons.polyline_outlined,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: StatCard(
                  title: l10n.translate('wp_circle_radii'),
                  value: l10n.formatNumber(controller.circleCount),
                  icon: Icons.radar_outlined,
                  iconColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Filter Bar
          FilterBar(
            searchHint: l10n.translate('search_placeholder'),
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchWorkplaces,
            filterActions: [
              // Geofence Type Filter Dropdown
              DropdownButton<GeofenceType?>(
                value: controller.geofenceTypeFilter,
                hint: Text(l10n.translate('wp_all_types')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('wp_all_types'))),
                  ...GeofenceType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  ),
                ],
                onChanged: controller.onFilterGeofenceType,
              ),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              DropdownButton<bool?>(
                value: controller.statusFilter,
                hint: Text(l10n.translate('emp_all_statuses')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_statuses'))),
                  DropdownMenuItem(value: true, child: Text(l10n.translate('wp_active_only'))),
                  DropdownMenuItem(value: false, child: Text(l10n.translate('wp_inactive_only'))),
                ],
                onChanged: controller.onFilterStatus,
              ),
              const SizedBox(width: 8),

              if (canCreate)
                HrButton(
                  label: l10n.translate('wp_add_btn'),
                  icon: Icons.add_location_alt_outlined,
                  onPressed: () => _openCreateDialog(context, controller),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Data Table
          HrDataTable<WorkplaceEntity>(
            isLoading: controller.isLoading && controller.workplaces.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchWorkplaces,
            items: controller.workplaces,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchWorkplaces(page: page),
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('wp_name_loc'),
                cellBuilder: (w) => Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: w.geofenceType == GeofenceType.polygon
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        w.geofenceType == GeofenceType.polygon ? Icons.polyline : Icons.circle_outlined,
                        color: w.geofenceType == GeofenceType.polygon ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.name, style: AppTypography.bodyBold),
                          Text(
                            w.address,
                            style: AppTypography.captionOf(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('wp_geofence_model'),
                cellBuilder: (w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: w.geofenceType == GeofenceType.polygon
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: w.geofenceType == GeofenceType.polygon
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFF6366F1).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        w.geofenceType == GeofenceType.polygon ? Icons.polyline_outlined : Icons.radar_outlined,
                        size: 14,
                        color: w.geofenceType == GeofenceType.polygon ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        w.geofenceType.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: w.geofenceType == GeofenceType.polygon ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('wp_boundary_specs'),
                cellBuilder: (w) {
                  if (w.geofenceType == GeofenceType.polygon) {
                    final area = GeofenceMath.calculateAreaSquareMeters(w.polygonPoints).toInt();
                    return Text('${w.polygonPoints.length} Vertices • ~$area m²', style: AppTypography.bodyMedium);
                  } else {
                    return Text('${w.allowedRadiusMeters.toInt()}m Radius', style: AppTypography.bodyMedium);
                  }
                },
              ),
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('wp_assigned_staff'),
                cellBuilder: (w) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 4),
                    Text('${w.assignedEmployeesCount}', style: AppTypography.body),
                  ],
                ),
              ),
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('status'),
                cellBuilder: (w) => w.isActive
                    ? StatusBadge(label: l10n.translate('wp_active_only'), variant: BadgeVariant.success)
                    : StatusBadge(label: l10n.translate('wp_inactive_only'), variant: BadgeVariant.neutral),
              ),
              HrColumn<WorkplaceEntity>(
                title: l10n.translate('actions'),
                cellBuilder: (w) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.preview_outlined, size: 18),
                      tooltip: l10n.translate('wp_preview_btn'),
                      onPressed: () => _openPreviewDialog(context, w),
                    ),
                    if (canUpdate) ...[
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                        tooltip: l10n.translate('wp_assign_staff'),
                        onPressed: () => _openAssignStaffDialog(context, w, controller),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: l10n.translate('wp_edit'),
                        onPressed: () => _openEditDialog(context, w, controller),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (action) {
                          if (action == 'toggle_status') {
                            controller.toggleWorkplaceStatus(w.id, !w.isActive);
                          } else if (action == 'delete') {
                            _confirmDelete(context, w, controller);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Text(w.isActive ? l10n.translate('emp_deactivate') : l10n.translate('emp_activate')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.translate('wp_delete'), style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WorkplaceEntity wp, WorkplaceController controller) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('wp_delete')),
        content: Text(l10n.isArabic
            ? 'هل أنت متأكد من رغبتك في حذف "${wp.name}"؟ لا يمكن التراجع عن هذا الإجراء.'
            : 'Are you sure you want to delete "${wp.name}"? This action cannot be undone.'),
        actions: [
          HrButton(
            label: l10n.translate('cancel'),
            variant: HrButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
          HrButton(
            label: l10n.translate('delete'),
            variant: HrButtonVariant.danger,
            onPressed: () {
              controller.deleteWorkplace(wp.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
