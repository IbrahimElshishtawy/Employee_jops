enum EmployeeAvailability {
  available,
  busy,
  away,
  offline;

  bool get isAvailable => this == EmployeeAvailability.available;
}

class EmployeeContact {
  final String id;
  final String fullName;
  final String jobTitleAr;
  final String jobTitleEn;
  final String departmentId;
  final String? departmentNameAr;
  final String? departmentNameEn;
  final String? avatarUrl;
  final bool isOnline;
  final EmployeeAvailability availability;
  final DateTime? lastSeen;
  final bool canChat;
  final bool canCreateRequest;
  final String? phone;
  final String? email;

  const EmployeeContact({
    required this.id,
    required this.fullName,
    required this.jobTitleAr,
    required this.jobTitleEn,
    required this.departmentId,
    this.departmentNameAr,
    this.departmentNameEn,
    this.avatarUrl,
    this.isOnline = false,
    this.availability = EmployeeAvailability.offline,
    this.lastSeen,
    this.canChat = true,
    this.canCreateRequest = true,
    this.phone,
    this.email,
  });

  String localizedJobTitle(bool isArabic) => isArabic ? jobTitleAr : jobTitleEn;
  String? localizedDepartment(bool isArabic) =>
      isArabic ? departmentNameAr : departmentNameEn;

  EmployeeContact copyWith({
    String? id,
    String? fullName,
    String? jobTitleAr,
    String? jobTitleEn,
    String? departmentId,
    String? departmentNameAr,
    String? departmentNameEn,
    String? avatarUrl,
    bool? isOnline,
    EmployeeAvailability? availability,
    DateTime? lastSeen,
    bool? canChat,
    bool? canCreateRequest,
    String? phone,
    String? email,
  }) {
    return EmployeeContact(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      jobTitleAr: jobTitleAr ?? this.jobTitleAr,
      jobTitleEn: jobTitleEn ?? this.jobTitleEn,
      departmentId: departmentId ?? this.departmentId,
      departmentNameAr: departmentNameAr ?? this.departmentNameAr,
      departmentNameEn: departmentNameEn ?? this.departmentNameEn,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      availability: availability ?? this.availability,
      lastSeen: lastSeen ?? this.lastSeen,
      canChat: canChat ?? this.canChat,
      canCreateRequest: canCreateRequest ?? this.canCreateRequest,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
