enum RequestPriority {
  low,
  normal,
  high;

  String localizedName(bool isArabic) {
    switch (this) {
      case RequestPriority.low:
        return isArabic ? 'منخفض' : 'Low';
      case RequestPriority.normal:
        return isArabic ? 'عادي' : 'Normal';
      case RequestPriority.high:
        return isArabic ? 'عالي' : 'High';
    }
  }
}

enum DepartmentRequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  rejected,
  cancelled;

  bool get isTerminal =>
      this == DepartmentRequestStatus.completed ||
      this == DepartmentRequestStatus.rejected ||
      this == DepartmentRequestStatus.cancelled;

  bool get isActive => !isTerminal;

  String localizedName(bool isArabic) {
    switch (this) {
      case DepartmentRequestStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case DepartmentRequestStatus.accepted:
        return isArabic ? 'تم القبول' : 'Accepted';
      case DepartmentRequestStatus.inProgress:
        return isArabic ? 'جاري التنفيذ' : 'In Progress';
      case DepartmentRequestStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
      case DepartmentRequestStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case DepartmentRequestStatus.cancelled:
        return isArabic ? 'ملغي' : 'Cancelled';
    }
  }
}

class DepartmentRequest {
  final String id;
  final String departmentId;
  final String? departmentNameAr;
  final String? departmentNameEn;
  final String requesterId;
  final String requesterName;
  final String? recipientId;
  final String? recipientName;
  final String requestTypeId;
  final String? requestTypeNameAr;
  final String? requestTypeNameEn;
  final RequestPriority priority;
  final String message;
  final String? locationContext;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DepartmentRequestStatus status;
  final String? rejectionReason;

  const DepartmentRequest({
    required this.id,
    required this.departmentId,
    this.departmentNameAr,
    this.departmentNameEn,
    required this.requesterId,
    required this.requesterName,
    this.recipientId,
    this.recipientName,
    required this.requestTypeId,
    this.requestTypeNameAr,
    this.requestTypeNameEn,
    this.priority = RequestPriority.normal,
    required this.message,
    this.locationContext,
    required this.createdAt,
    this.updatedAt,
    this.status = DepartmentRequestStatus.pending,
    this.rejectionReason,
  });

  String localizedDepartment(bool isArabic) =>
      (isArabic ? departmentNameAr : departmentNameEn) ?? departmentId;

  String localizedRequestType(bool isArabic) =>
      (isArabic ? requestTypeNameAr : requestTypeNameEn) ?? requestTypeId;

  DepartmentRequest copyWith({
    String? id,
    String? departmentId,
    String? departmentNameAr,
    String? departmentNameEn,
    String? requesterId,
    String? requesterName,
    String? recipientId,
    String? recipientName,
    String? requestTypeId,
    String? requestTypeNameAr,
    String? requestTypeNameEn,
    RequestPriority? priority,
    String? message,
    String? locationContext,
    DateTime? createdAt,
    DateTime? updatedAt,
    DepartmentRequestStatus? status,
    String? rejectionReason,
  }) {
    return DepartmentRequest(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      departmentNameAr: departmentNameAr ?? this.departmentNameAr,
      departmentNameEn: departmentNameEn ?? this.departmentNameEn,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      requestTypeId: requestTypeId ?? this.requestTypeId,
      requestTypeNameAr: requestTypeNameAr ?? this.requestTypeNameAr,
      requestTypeNameEn: requestTypeNameEn ?? this.requestTypeNameEn,
      priority: priority ?? this.priority,
      message: message ?? this.message,
      locationContext: locationContext ?? this.locationContext,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
