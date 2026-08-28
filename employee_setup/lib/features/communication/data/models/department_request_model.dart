import '../../domain/entities/department_request.dart';

class DepartmentRequestModel extends DepartmentRequest {
  const DepartmentRequestModel({
    required super.id,
    required super.departmentId,
    super.departmentNameAr,
    super.departmentNameEn,
    required super.requesterId,
    required super.requesterName,
    super.recipientId,
    super.recipientName,
    required super.requestTypeId,
    super.requestTypeNameAr,
    super.requestTypeNameEn,
    super.priority,
    required super.message,
    super.locationContext,
    required super.createdAt,
    super.updatedAt,
    super.status,
    super.rejectionReason,
  });

  factory DepartmentRequestModel.fromJson(Map<String, dynamic> json) {
    RequestPriority parsePriority(String? val) {
      switch (val?.toLowerCase()) {
        case 'low':
          return RequestPriority.low;
        case 'high':
          return RequestPriority.high;
        default:
          return RequestPriority.normal;
      }
    }

    DepartmentRequestStatus parseStatus(String? val) {
      switch (val?.toLowerCase()) {
        case 'accepted':
          return DepartmentRequestStatus.accepted;
        case 'inprogress':
        case 'in_progress':
          return DepartmentRequestStatus.inProgress;
        case 'completed':
          return DepartmentRequestStatus.completed;
        case 'rejected':
          return DepartmentRequestStatus.rejected;
        case 'cancelled':
          return DepartmentRequestStatus.cancelled;
        default:
          return DepartmentRequestStatus.pending;
      }
    }

    return DepartmentRequestModel(
      id: json['id'] as String,
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      departmentNameAr: json['departmentNameAr'] as String? ?? json['department_name_ar'] as String?,
      departmentNameEn: json['departmentNameEn'] as String? ?? json['department_name_en'] as String?,
      requesterId: json['requesterId'] as String? ?? json['requester_id'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? json['requester_name'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? json['recipient_id'] as String?,
      recipientName: json['recipientName'] as String? ?? json['recipient_name'] as String?,
      requestTypeId: json['requestTypeId'] as String? ?? json['request_type_id'] as String? ?? '',
      requestTypeNameAr: json['requestTypeNameAr'] as String? ?? json['request_type_name_ar'] as String?,
      requestTypeNameEn: json['requestTypeNameEn'] as String? ?? json['request_type_name_en'] as String?,
      priority: parsePriority(json['priority'] as String?),
      message: json['message'] as String? ?? '',
      locationContext: json['locationContext'] as String? ?? json['location_context'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null),
      status: parseStatus(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String? ?? json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departmentId': departmentId,
      'departmentNameAr': departmentNameAr,
      'departmentNameEn': departmentNameEn,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'requestTypeId': requestTypeId,
      'requestTypeNameAr': requestTypeNameAr,
      'requestTypeNameEn': requestTypeNameEn,
      'priority': priority.name,
      'message': message,
      'locationContext': locationContext,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'rejectionReason': rejectionReason,
    };
  }

  factory DepartmentRequestModel.fromEntity(DepartmentRequest entity) {
    return DepartmentRequestModel(
      id: entity.id,
      departmentId: entity.departmentId,
      departmentNameAr: entity.departmentNameAr,
      departmentNameEn: entity.departmentNameEn,
      requesterId: entity.requesterId,
      requesterName: entity.requesterName,
      recipientId: entity.recipientId,
      recipientName: entity.recipientName,
      requestTypeId: entity.requestTypeId,
      requestTypeNameAr: entity.requestTypeNameAr,
      requestTypeNameEn: entity.requestTypeNameEn,
      priority: entity.priority,
      message: entity.message,
      locationContext: entity.locationContext,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      status: entity.status,
      rejectionReason: entity.rejectionReason,
    );
  }
}
