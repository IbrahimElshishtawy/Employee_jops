import '../../../employees/domain/entities/employee_entity.dart';

/// Workplace entity with authoritative geo-fencing radius
class WorkplaceEntity {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double allowedRadiusMeters;
  final bool isActive;
  final int assignedEmployeesCount;
  final DateTime createdAt;

  const WorkplaceEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
    required this.isActive,
    required this.assignedEmployeesCount,
    required this.createdAt,
  });
}

abstract class WorkplacesRepository {
  Future<PaginatedList<WorkplaceEntity>> getWorkplaces(int page, int pageSize);
  Future<WorkplaceEntity> createWorkplace(WorkplaceEntity workplace);
  Future<WorkplaceEntity> updateWorkplace(WorkplaceEntity workplace);
}

class MockWorkplacesRepository implements WorkplacesRepository {
  final List<WorkplaceEntity> _mockWorkplaces = [
    WorkplaceEntity(
      id: 'WP-001',
      name: 'HQ Main Tower',
      address: 'Plot 104, Tech Park Boulevard',
      latitude: 30.0444,
      longitude: 31.2357,
      allowedRadiusMeters: 150.0,
      isActive: true,
      assignedEmployeesCount: 32,
      createdAt: DateTime(2023, 1, 1),
    ),
    WorkplaceEntity(
      id: 'WP-002',
      name: 'Tech Hub Branch',
      address: 'Building 7B, Cyber District',
      latitude: 30.0131,
      longitude: 31.2089,
      allowedRadiusMeters: 100.0,
      isActive: true,
      assignedEmployeesCount: 16,
      createdAt: DateTime(2023, 4, 15),
    ),
  ];

  @override
  Future<PaginatedList<WorkplaceEntity>> getWorkplaces(int page, int pageSize) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return PaginatedList<WorkplaceEntity>(
      items: _mockWorkplaces,
      totalCount: _mockWorkplaces.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<WorkplaceEntity> createWorkplace(WorkplaceEntity workplace) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockWorkplaces.add(workplace);
    return workplace;
  }

  @override
  Future<WorkplaceEntity> updateWorkplace(WorkplaceEntity workplace) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockWorkplaces.indexWhere((w) => w.id == workplace.id);
    if (index != -1) _mockWorkplaces[index] = workplace;
    return workplace;
  }
}
