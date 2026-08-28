class Department {
  final String id;
  final String nameAr;
  final String nameEn;
  final String iconName;
  final String? descriptionAr;
  final String? descriptionEn;
  final int availableEmployeesCount;
  final int totalEmployeesCount;

  const Department({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconName,
    this.descriptionAr,
    this.descriptionEn,
    this.availableEmployeesCount = 0,
    this.totalEmployeesCount = 0,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
  String? localizedDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;

  bool get hasAvailableEmployees => availableEmployeesCount > 0;

  Department copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? iconName,
    String? descriptionAr,
    String? descriptionEn,
    int? availableEmployeesCount,
    int? totalEmployeesCount,
  }) {
    return Department(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      iconName: iconName ?? this.iconName,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      availableEmployeesCount:
          availableEmployeesCount ?? this.availableEmployeesCount,
      totalEmployeesCount: totalEmployeesCount ?? this.totalEmployeesCount,
    );
  }
}
