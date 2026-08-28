import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.iconName,
    super.descriptionAr,
    super.descriptionEn,
    super.availableEmployeesCount,
    super.totalEmployeesCount,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      iconName: json['iconName'] as String? ?? json['icon_name'] as String? ?? 'business',
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
      availableEmployeesCount: json['availableEmployeesCount'] as int? ?? json['available_employees_count'] as int? ?? 0,
      totalEmployeesCount: json['totalEmployeesCount'] as int? ?? json['total_employees_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconName': iconName,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'availableEmployeesCount': availableEmployeesCount,
      'totalEmployeesCount': totalEmployeesCount,
    };
  }

  factory DepartmentModel.fromEntity(Department entity) {
    return DepartmentModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      iconName: entity.iconName,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
      availableEmployeesCount: entity.availableEmployeesCount,
      totalEmployeesCount: entity.totalEmployeesCount,
    );
  }
}
