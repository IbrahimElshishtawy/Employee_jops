import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/data/models/employee_dto.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/workplace_entity.dart';
import '../models/workplace_dto.dart';

/// Live Production REST API Workplace Repository
class ApiWorkplacesRepository implements WorkplacesRepository {
  final ApiClient _apiClient;

  ApiWorkplacesRepository(this._apiClient);

  @override
  Future<PaginatedList<WorkplaceEntity>> getWorkplaces(WorkplaceFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        queryParams['q'] = filter.searchQuery!;
      }
      if (filter.geofenceType != null) {
        queryParams['geofenceType'] = filter.geofenceType!.key;
      }
      if (filter.isActive != null) {
        queryParams['isActive'] = filter.isActive.toString();
      }

      final response = await _apiClient.get(
        ApiEndpoints.workplaces,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => WorkplaceDto.fromJson(e as Map<String, dynamic>).toDomain()).toList();
          return PaginatedList<WorkplaceEntity>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<WorkplaceEntity> getWorkplaceById(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.workplaceDetails(id),
        parser: (data) => WorkplaceDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<WorkplaceEntity> createWorkplace(WorkplaceEntity workplace) async {
    try {
      final dto = WorkplaceDto.fromDomain(workplace);
      final response = await _apiClient.post(
        ApiEndpoints.workplaces,
        body: dto.toJson(),
        parser: (data) => WorkplaceDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<WorkplaceEntity> updateWorkplace(WorkplaceEntity workplace) async {
    try {
      final dto = WorkplaceDto.fromDomain(workplace);
      final response = await _apiClient.put(
        ApiEndpoints.workplaceDetails(workplace.id),
        body: dto.toJson(),
        parser: (data) => WorkplaceDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> toggleStatus(String id, bool isActive) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.workplaces}/$id/status',
        body: {'isActive': isActive},
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteWorkplace(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.workplaceDetails(id));
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<EmployeeEntity>> getAssignedEmployees(String workplaceId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.workplaces}/$workplaceId/employees',
        parser: (data) {
          final rawList = data as List<dynamic>? ?? [];
          return rawList.map((e) => EmployeeDto.fromJson(e as Map<String, dynamic>).toDomain()).toList();
        },
      );
      return response.data ?? [];
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> assignEmployees(String workplaceId, List<String> employeeIds) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.workplaces}/$workplaceId/employees',
        body: {'employeeIds': employeeIds},
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
