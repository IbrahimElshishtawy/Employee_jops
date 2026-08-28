import '../../domain/entities/request_type.dart';

class RequestTypeModel extends RequestType {
  const RequestTypeModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    super.departmentId,
    super.descriptionAr,
    super.descriptionEn,
  });

  factory RequestTypeModel.fromJson(Map<String, dynamic> json) {
    return RequestTypeModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'departmentId': departmentId,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
    };
  }

  factory RequestTypeModel.fromEntity(RequestType entity) {
    return RequestTypeModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      departmentId: entity.departmentId,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
    );
  }
}
