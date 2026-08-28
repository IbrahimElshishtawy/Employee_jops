import '../../domain/entities/employee_contact.dart';

class EmployeeContactModel extends EmployeeContact {
  const EmployeeContactModel({
    required super.id,
    required super.fullName,
    required super.jobTitleAr,
    required super.jobTitleEn,
    required super.departmentId,
    super.departmentNameAr,
    super.departmentNameEn,
    super.avatarUrl,
    super.isOnline,
    super.availability,
    super.lastSeen,
    super.canChat,
    super.canCreateRequest,
    super.phone,
    super.email,
  });

  factory EmployeeContactModel.fromJson(Map<String, dynamic> json) {
    EmployeeAvailability parseAvailability(String? val) {
      switch (val?.toLowerCase()) {
        case 'available':
          return EmployeeAvailability.available;
        case 'busy':
          return EmployeeAvailability.busy;
        case 'away':
          return EmployeeAvailability.away;
        default:
          return EmployeeAvailability.offline;
      }
    }

    return EmployeeContactModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      jobTitleAr: json['jobTitleAr'] as String? ?? json['job_title_ar'] as String? ?? '',
      jobTitleEn: json['jobTitleEn'] as String? ?? json['job_title_en'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      departmentNameAr: json['departmentNameAr'] as String? ?? json['department_name_ar'] as String?,
      departmentNameEn: json['departmentNameEn'] as String? ?? json['department_name_en'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? false,
      availability: parseAvailability(json['availability'] as String?),
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'] as String) : null,
      canChat: json['canChat'] as bool? ?? json['can_chat'] as bool? ?? true,
      canCreateRequest: json['canCreateRequest'] as bool? ?? json['can_create_request'] as bool? ?? true,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'jobTitleAr': jobTitleAr,
      'jobTitleEn': jobTitleEn,
      'departmentId': departmentId,
      'departmentNameAr': departmentNameAr,
      'departmentNameEn': departmentNameEn,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'availability': availability.name,
      'lastSeen': lastSeen?.toIso8601String(),
      'canChat': canChat,
      'canCreateRequest': canCreateRequest,
      'phone': phone,
      'email': email,
    };
  }

  factory EmployeeContactModel.fromEntity(EmployeeContact entity) {
    return EmployeeContactModel(
      id: entity.id,
      fullName: entity.fullName,
      jobTitleAr: entity.jobTitleAr,
      jobTitleEn: entity.jobTitleEn,
      departmentId: entity.departmentId,
      departmentNameAr: entity.departmentNameAr,
      departmentNameEn: entity.departmentNameEn,
      avatarUrl: entity.avatarUrl,
      isOnline: entity.isOnline,
      availability: entity.availability,
      lastSeen: entity.lastSeen,
      canChat: entity.canChat,
      canCreateRequest: entity.canCreateRequest,
      phone: entity.phone,
      email: entity.email,
    );
  }
}
