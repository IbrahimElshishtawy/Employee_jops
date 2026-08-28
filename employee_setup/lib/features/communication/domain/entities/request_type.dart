class RequestType {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? departmentId;
  final String? descriptionAr;
  final String? descriptionEn;

  const RequestType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.departmentId,
    this.descriptionAr,
    this.descriptionEn,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
}
