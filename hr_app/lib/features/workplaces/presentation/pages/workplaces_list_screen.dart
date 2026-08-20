import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/workplace_entity.dart';

/// Workplaces Management Screen
class WorkplacesListScreen extends StatefulWidget {
  final WorkplacesRepository repository;

  const WorkplacesListScreen({super.key, required this.repository});

  @override
  State<WorkplacesListScreen> createState() => _WorkplacesListScreenState();
}

class _WorkplacesListScreenState extends State<WorkplacesListScreen> {
  List<WorkplaceEntity> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkplaces();
  }

  Future<void> _loadWorkplaces() async {
    setState(() => _isLoading = true);
    final res = await widget.repository.getWorkplaces(1, 10);
    setState(() {
      _items = res.items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          searchHint: 'Search workplaces...',
          onRefresh: _loadWorkplaces,
          filterActions: [
            HrButton(
              label: 'Add Workplace',
              icon: Icons.add_location_alt_outlined,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),
        HrDataTable<WorkplaceEntity>(
          isLoading: _isLoading,
          items: _items,
          totalItems: _items.length,
          columns: [
            HrColumn<WorkplaceEntity>(
              title: 'Workplace Name',
              cellBuilder: (w) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(w.name, style: AppTypography.bodyBold),
                  Text(w.address, style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<WorkplaceEntity>(
              title: 'Coordinates (Lat, Lng)',
              cellBuilder: (w) => Text('${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)}', style: AppTypography.body),
            ),
            HrColumn<WorkplaceEntity>(
              title: 'Allowed Radius',
              cellBuilder: (w) => Text('${w.allowedRadiusMeters.toInt()} meters', style: AppTypography.bodyMedium),
            ),
            HrColumn<WorkplaceEntity>(
              title: 'Assigned Staff',
              cellBuilder: (w) => Text('${w.assignedEmployeesCount} employees', style: AppTypography.body),
            ),
            HrColumn<WorkplaceEntity>(
              title: 'Status',
              cellBuilder: (w) => w.isActive
                  ? const StatusBadge(label: 'Active Geofence', variant: BadgeVariant.success)
                  : const StatusBadge(label: 'Inactive', variant: BadgeVariant.neutral),
            ),
          ],
        ),
      ],
    );
  }
}
