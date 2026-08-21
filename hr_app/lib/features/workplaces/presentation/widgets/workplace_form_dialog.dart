import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/workplace_entity.dart';
import '../../domain/utils/geofence_math.dart';
import 'workplace_boundary_preview_widget.dart';
import 'workplace_map_editor_widget.dart';

/// Modal Dialog for Creating or Editing a Workplace with Geofence Definition
class WorkplaceFormDialog extends StatefulWidget {
  final WorkplaceEntity? workplace; // null for Create mode
  final ValueChanged<WorkplaceEntity> onSave;

  const WorkplaceFormDialog({
    super.key,
    this.workplace,
    required this.onSave,
  });

  @override
  State<WorkplaceFormDialog> createState() => _WorkplaceFormDialogState();
}

class _WorkplaceFormDialogState extends State<WorkplaceFormDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late GeofenceType _geofenceType;
  late double _centerLat;
  late double _centerLng;
  late double _radiusMeters;
  late List<GeoCoordinate> _polygonPoints;
  late bool _isActive;

  late TabController _tabController;
  String? _formError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final wp = widget.workplace;
    _nameController = TextEditingController(text: wp?.name ?? '');
    _addressController = TextEditingController(text: wp?.address ?? '');
    _geofenceType = wp?.geofenceType ?? GeofenceType.polygon;
    _centerLat = wp?.latitude ?? 30.0732; // Default to Smart Village
    _centerLng = wp?.longitude ?? 31.0185;
    _radiusMeters = wp?.allowedRadiusMeters ?? 150.0;
    _polygonPoints = wp != null
        ? List<GeoCoordinate>.from(wp.polygonPoints)
        : [
            GeoCoordinate(latitude: _centerLat + 0.0015, longitude: _centerLng - 0.0015, label: 'P1'),
            GeoCoordinate(latitude: _centerLat + 0.0015, longitude: _centerLng + 0.0015, label: 'P2'),
            GeoCoordinate(latitude: _centerLat - 0.0015, longitude: _centerLng + 0.0015, label: 'P3'),
            GeoCoordinate(latitude: _centerLat - 0.0015, longitude: _centerLng - 0.0015, label: 'P4'),
          ];
    _isActive = wp?.isActive ?? true;

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  WorkplaceEntity _buildEntity() {
    final centroid = _geofenceType == GeofenceType.polygon && _polygonPoints.isNotEmpty
        ? GeofenceMath.calculateCentroid(_polygonPoints)
        : GeoCoordinate(latitude: _centerLat, longitude: _centerLng);

    return WorkplaceEntity(
      id: widget.workplace?.id ?? '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      geofenceType: _geofenceType,
      latitude: centroid.latitude,
      longitude: centroid.longitude,
      allowedRadiusMeters: _radiusMeters,
      polygonPoints: _geofenceType == GeofenceType.polygon ? _polygonPoints : const [],
      isActive: _isActive,
      assignedEmployeesCount: widget.workplace?.assignedEmployeesCount ?? 0,
      assignedEmployeeIds: widget.workplace?.assignedEmployeeIds ?? const [],
      createdAt: widget.workplace?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _onSavePressed() {
    setState(() => _formError = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _formError = 'Please enter a workplace name.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _formError = 'Please enter a physical address.');
      return;
    }

    if (_geofenceType == GeofenceType.polygon) {
      final validationError = GeofenceMath.validatePolygon(_polygonPoints);
      if (validationError != null) {
        setState(() => _formError = validationError);
        return;
      }
    } else {
      if (_radiusMeters < 10) {
        setState(() => _formError = 'Circle radius must be at least 10 meters.');
        return;
      }
    }

    setState(() => _isSaving = true);
    final entity = _buildEntity();
    widget.onSave(entity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.workplace != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: Container(
        width: 820,
        height: 720,
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
                  color: AppColors.primaryLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Workplace Geofence' : 'Create New Workplace',
                  style: AppTypography.heading2,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Geofence Editor'),
                Tab(icon: Icon(Icons.preview_outlined, size: 18), text: 'Boundary Preview & Simulator'),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.errorLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorLight, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_formError!, style: const TextStyle(color: AppColors.errorLight, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
            ],

            // Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Form & Interactive Map Editor
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic Info Fields
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: HrTextField(
                                label: 'Workplace Name',
                                hint: 'e.g. HQ Main Campus (Smart Village)',
                                controller: _nameController,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              flex: 4,
                              child: HrTextField(
                                label: 'Physical Address',
                                hint: 'e.g. Km 28 Cairo-Alex Desert Road',
                                controller: _addressController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Geofence Type Selector & Active Toggle
                        Row(
                          children: [
                            Text('Geofence Model:', style: AppTypography.bodyBold),
                            const SizedBox(width: AppDimensions.space12),
                            SegmentedButton<GeofenceType>(
                              segments: const [
                                ButtonSegment(
                                  value: GeofenceType.polygon,
                                  label: Text('Polygon Boundary'),
                                  icon: Icon(Icons.polyline_outlined, size: 16),
                                ),
                                ButtonSegment(
                                  value: GeofenceType.circle,
                                  label: Text('Circle Radius'),
                                  icon: Icon(Icons.circle_outlined, size: 16),
                                ),
                              ],
                              selected: {_geofenceType},
                              onSelectionChanged: (set) {
                                setState(() => _geofenceType = set.first);
                              },
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Active Status', style: AppTypography.bodyMedium),
                                Switch(
                                  value: _isActive,
                                  onChanged: (val) => setState(() => _isActive = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Map Editor
                        WorkplaceMapEditorWidget(
                          geofenceType: _geofenceType,
                          centerLatitude: _centerLat,
                          centerLongitude: _centerLng,
                          radiusMeters: _radiusMeters,
                          polygonPoints: _polygonPoints,
                          onCenterChanged: (c) {
                            setState(() {
                              _centerLat = c.latitude;
                              _centerLng = c.longitude;
                            });
                          },
                          onRadiusChanged: (r) => setState(() => _radiusMeters = r),
                          onPolygonChanged: (pts) => setState(() => _polygonPoints = pts),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Boundary Preview & Attendance Simulator
                  SingleChildScrollView(
                    child: WorkplaceBoundaryPreviewWidget(
                      workplace: _buildEntity(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Footer Actions
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
                  label: isEdit ? 'Save Changes' : 'Create Workplace',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _onSavePressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
