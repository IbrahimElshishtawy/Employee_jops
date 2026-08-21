import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/employee_entity.dart';
import '../models/employee_dto.dart';

/// Live Production Employee Repository
class ApiEmployeeRepository implements EmployeeRepository {
  final ApiClient _apiClient;

  ApiEmployeeRepository(this._apiClient);

  @override
  Future<PaginatedList<EmployeeEntity>> getEmployees(EmployeeFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.workplaceId != null) queryParams['workplaceId'] = filter.workplaceId!;

      final response = await _apiClient.get(
        ApiEndpoints.employees,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => EmployeeDto.fromJson(e as Map<String, dynamic>).toDomain()).toList();
          return PaginatedList<EmployeeEntity>(
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
  Future<EmployeeEntity> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.employeeDetails(id),
        parser: (data) => EmployeeDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<EmployeeEntity> createEmployee(EmployeeEntity employee) async {
    try {
      final dto = EmployeeDto(
        id: employee.id,
        employeeCode: employee.employeeCode,
        fullName: employee.fullName,
        email: employee.email,
        phone: employee.phone,
        department: employee.department,
        jobTitle: employee.jobTitle,
        workplaceId: employee.workplaceId,
        workplaceName: employee.workplaceName,
        scheduleId: employee.scheduleId,
        scheduleName: employee.scheduleName,
        managerName: employee.managerName,
        status: employee.status.key,
        joinedDate: employee.joinedDate.toIso8601String(),
      );
      final response = await _apiClient.post(
        ApiEndpoints.employees,
        body: dto.toJson(),
        parser: (data) => EmployeeDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<EmployeeEntity> updateEmployee(EmployeeEntity employee) async {
    try {
      final dto = EmployeeDto(
        id: employee.id,
        employeeCode: employee.employeeCode,
        fullName: employee.fullName,
        email: employee.email,
        phone: employee.phone,
        department: employee.department,
        jobTitle: employee.jobTitle,
        workplaceId: employee.workplaceId,
        workplaceName: employee.workplaceName,
        scheduleId: employee.scheduleId,
        scheduleName: employee.scheduleName,
        managerName: employee.managerName,
        status: employee.status.key,
        joinedDate: employee.joinedDate.toIso8601String(),
      );
      final response = await _apiClient.put(
        ApiEndpoints.employeeDetails(employee.id),
        body: dto.toJson(),
        parser: (data) => EmployeeDto.fromJson(data as Map<String, dynamic>).toDomain(),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateStatus(String id, EmployeeStatus status) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.employeeStatus(id),
        body: {'status': status.key},
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> assignWorkplaceAndSchedule(
    String id, {
    required String workplaceId,
    required String workplaceName,
    required String scheduleId,
    required String scheduleName,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.employeeDetails(id),
        body: {
          'workplaceId': workplaceId,
          'scheduleId': scheduleId,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
