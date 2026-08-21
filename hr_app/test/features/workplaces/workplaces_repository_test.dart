import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/features/workplaces/data/repositories/mock_workplaces_repository.dart';
import 'package:hr_app/features/workplaces/domain/entities/workplace_entity.dart';

void main() {
  group('MockWorkplacesRepository Tests', () {
    late MockWorkplacesRepository repository;

    setUp(() {
      repository = MockWorkplacesRepository();
    });

    test('getWorkplaces returns populated paginated list with polygon and circle geofences', () async {
      final res = await repository.getWorkplaces(const WorkplaceFilter(page: 1, pageSize: 10));
      expect(res.items.isNotEmpty, isTrue);
      expect(res.totalCount, greaterThanOrEqualTo(4));

      final hasPolygon = res.items.any((w) => w.geofenceType == GeofenceType.polygon);
      final hasCircle = res.items.any((w) => w.geofenceType == GeofenceType.circle);

      expect(hasPolygon, isTrue);
      expect(hasCircle, isTrue);
    });

    test('createWorkplace successfully adds a new workplace', () async {
      final newWp = WorkplaceEntity(
        id: '',
        name: 'New Test Branch',
        address: 'Test Address 123',
        geofenceType: GeofenceType.polygon,
        latitude: 30.05,
        longitude: 31.25,
        allowedRadiusMeters: 100,
        polygonPoints: const [
          GeoCoordinate(latitude: 30.051, longitude: 31.251),
          GeoCoordinate(latitude: 30.051, longitude: 31.252),
          GeoCoordinate(latitude: 30.050, longitude: 31.252),
        ],
        isActive: true,
        assignedEmployeesCount: 0,
        createdAt: DateTime.now(),
      );

      final created = await repository.createWorkplace(newWp);
      expect(created.id, isNotEmpty);
      expect(created.name, 'New Test Branch');

      final fetched = await repository.getWorkplaceById(created.id);
      expect(fetched.name, 'New Test Branch');
    });

    test('toggleStatus updates active state', () async {
      await repository.toggleStatus('WP-001', false);
      final wp = await repository.getWorkplaceById('WP-001');
      expect(wp.isActive, isFalse);

      await repository.toggleStatus('WP-001', true);
      final wpActive = await repository.getWorkplaceById('WP-001');
      expect(wpActive.isActive, isTrue);
    });

    test('assignEmployees updates assigned staff', () async {
      await repository.assignEmployees('WP-003', ['TEST-EMP-001', 'TEST-EMP-002']);
      final assigned = await repository.getAssignedEmployees('WP-003');
      expect(assigned.length, 2);
    });
  });
}
