import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/workplace_entity.dart';

/// In-Memory Mock Repository for Workplaces in CyberWise IE HR Portal
class MockWorkplacesRepository implements WorkplacesRepository {
  final List<WorkplaceEntity> _mockWorkplaces = [
    WorkplaceEntity(
      id: 'WP-001',
      name: 'HQ Main Campus (Smart Village)',
      address: 'Km 28 Cairo-Alexandria Desert Road, Smart Village B12',
      geofenceType: GeofenceType.polygon,
      latitude: 30.0732,
      longitude: 31.0185,
      allowedRadiusMeters: 250.0,
      polygonPoints: const [
        GeoCoordinate(latitude: 30.0745, longitude: 31.0170, label: 'North-West Gate'),
        GeoCoordinate(latitude: 30.0750, longitude: 31.0200, label: 'North-East Corner'),
        GeoCoordinate(latitude: 30.0730, longitude: 31.0210, label: 'East Parking'),
        GeoCoordinate(latitude: 30.0715, longitude: 31.0195, label: 'South Gate 2'),
        GeoCoordinate(latitude: 30.0720, longitude: 31.0165, label: 'West Logistics'),
      ],
      isActive: true,
      assignedEmployeesCount: 48,
      assignedEmployeeIds: ['TEST-EMP-001', 'TEST-EMP-002', 'TEST-EMP-003'],
      createdAt: DateTime(2023, 1, 1),
    ),
    WorkplaceEntity(
      id: 'WP-002',
      name: 'Cyber District Tech Hub',
      address: 'Building 7B, New Cairo Financial Center',
      geofenceType: GeofenceType.polygon,
      latitude: 30.0280,
      longitude: 31.4720,
      allowedRadiusMeters: 180.0,
      polygonPoints: const [
        GeoCoordinate(latitude: 30.0295, longitude: 31.4705, label: 'P1 Main Entrance'),
        GeoCoordinate(latitude: 30.0298, longitude: 31.4735, label: 'P2 East Plaza'),
        GeoCoordinate(latitude: 30.0270, longitude: 31.4740, label: 'P3 South Wing'),
        GeoCoordinate(latitude: 30.0265, longitude: 31.4710, label: 'P4 West Garden'),
      ],
      isActive: true,
      assignedEmployeesCount: 26,
      assignedEmployeeIds: ['TEST-EMP-004'],
      createdAt: DateTime(2023, 3, 15),
    ),
    WorkplaceEntity(
      id: 'WP-003',
      name: 'Alexandria Operations Hub',
      address: 'Fouad Street, Borg Al-Arab Technology Park',
      geofenceType: GeofenceType.circle,
      latitude: 31.2001,
      longitude: 29.9187,
      allowedRadiusMeters: 120.0,
      polygonPoints: const [],
      isActive: true,
      assignedEmployeesCount: 14,
      assignedEmployeeIds: ['TEST-EMP-005'],
      createdAt: DateTime(2023, 6, 20),
    ),
    WorkplaceEntity(
      id: 'WP-004',
      name: 'Maadi Technology Park Branch',
      address: 'Plot 3A, Wireless District, Maadi, Cairo',
      geofenceType: GeofenceType.circle,
      latitude: 29.9602,
      longitude: 31.2825,
      allowedRadiusMeters: 90.0,
      polygonPoints: const [],
      isActive: false,
      assignedEmployeesCount: 0,
      assignedEmployeeIds: const [],
      createdAt: DateTime(2023, 9, 10),
    ),
  ];

  final List<EmployeeEntity> _allEmployees = [
    EmployeeEntity(
      id: 'TEST-EMP-001',
      employeeCode: 'CW-1001',
      fullName: 'Ahmed Hassan',
      email: 'ahmed.hassan@cyberwise.ie',
      phone: '+20 100 123 4567',
      department: 'Engineering',
      jobTitle: 'Senior Full Stack Engineer',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Campus (Smart Village)',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Day Shift',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2022, 1, 10),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-002',
      employeeCode: 'CW-1002',
      fullName: 'Sara Mohamed',
      email: 'sara.mohamed@cyberwise.ie',
      phone: '+20 101 234 5678',
      department: 'Human Resources',
      jobTitle: 'HR Operations Lead',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Campus (Smart Village)',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Day Shift',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2022, 3, 15),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-003',
      employeeCode: 'CW-1003',
      fullName: 'Mahmoud Ali',
      email: 'mahmoud.ali@cyberwise.ie',
      phone: '+20 102 345 6789',
      department: 'Cybersecurity',
      jobTitle: 'SOC Lead Analyst',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Campus (Smart Village)',
      scheduleId: 'SCH-002',
      scheduleName: '24/7 Security Shift',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2022, 5, 1),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-004',
      employeeCode: 'CW-1004',
      fullName: 'Nour Ibrahim',
      email: 'nour.ibrahim@cyberwise.ie',
      phone: '+20 103 456 7890',
      department: 'Sales & BD',
      jobTitle: 'Enterprise Account Manager',
      workplaceId: 'WP-002',
      workplaceName: 'Cyber District Tech Hub',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Day Shift',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2022, 8, 20),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-005',
      employeeCode: 'CW-1005',
      fullName: 'Tarek Mahmoud',
      email: 'tarek.mahmoud@cyberwise.ie',
      phone: '+20 104 567 8901',
      department: 'Operations',
      jobTitle: 'Regional Logistics Coordinator',
      workplaceId: 'WP-003',
      workplaceName: 'Alexandria Operations Hub',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Day Shift',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2023, 2, 1),
    ),
  ];

  @override
  Future<PaginatedList<WorkplaceEntity>> getWorkplaces(WorkplaceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var list = List<WorkplaceEntity>.from(_mockWorkplaces);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      list = list.where((w) {
        return w.name.toLowerCase().contains(q) || w.address.toLowerCase().contains(q);
      }).toList();
    }

    if (filter.geofenceType != null) {
      list = list.where((w) => w.geofenceType == filter.geofenceType).toList();
    }

    if (filter.isActive != null) {
      list = list.where((w) => w.isActive == filter.isActive).toList();
    }

    final totalCount = list.length;
    final totalPages = (totalCount / filter.pageSize).ceil();
    final startIndex = (filter.page - 1) * filter.pageSize;
    final pagedItems = list.skip(startIndex).take(filter.pageSize).toList();

    return PaginatedList<WorkplaceEntity>(
      items: pagedItems,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  @override
  Future<WorkplaceEntity> getWorkplaceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final wp = _mockWorkplaces.firstWhere(
      (w) => w.id == id,
      orElse: () => throw Exception('Workplace $id not found'),
    );
    return wp;
  }

  @override
  Future<WorkplaceEntity> createWorkplace(WorkplaceEntity workplace) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final newId = 'WP-${(_mockWorkplaces.length + 1).toString().padLeft(3, '0')}';
    final created = workplace.copyWith(
      id: newId,
      createdAt: DateTime.now(),
      assignedEmployeesCount: 0,
      assignedEmployeeIds: const [],
    );
    _mockWorkplaces.insert(0, created);
    return created;
  }

  @override
  Future<WorkplaceEntity> updateWorkplace(WorkplaceEntity workplace) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockWorkplaces.indexWhere((w) => w.id == workplace.id);
    if (index == -1) {
      throw Exception('Workplace ${workplace.id} not found');
    }
    final updated = workplace.copyWith(updatedAt: DateTime.now());
    _mockWorkplaces[index] = updated;
    return updated;
  }

  @override
  Future<void> toggleStatus(String id, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _mockWorkplaces.indexWhere((w) => w.id == id);
    if (index != -1) {
      _mockWorkplaces[index] = _mockWorkplaces[index].copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteWorkplace(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockWorkplaces.removeWhere((w) => w.id == id);
  }

  @override
  Future<List<EmployeeEntity>> getAssignedEmployees(String workplaceId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final wp = _mockWorkplaces.firstWhere(
      (w) => w.id == workplaceId,
      orElse: () => throw Exception('Workplace not found'),
    );
    return _allEmployees.where((e) => wp.assignedEmployeeIds.contains(e.id)).toList();
  }

  @override
  Future<void> assignEmployees(String workplaceId, List<String> employeeIds) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockWorkplaces.indexWhere((w) => w.id == workplaceId);
    if (index != -1) {
      final current = _mockWorkplaces[index];
      _mockWorkplaces[index] = current.copyWith(
        assignedEmployeeIds: employeeIds,
        assignedEmployeesCount: employeeIds.length,
        updatedAt: DateTime.now(),
      );
    }
  }
}
