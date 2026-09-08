class LostFoundItem {
  final String id;
  final String itemName;
  final String description;
  final String category;
  final String locationFound;
  final DateTime foundDate;
  final String storageLocation;
  final String status;
  final List<String> images;

  const LostFoundItem({
    required this.id,
    required this.itemName,
    required this.description,
    required this.category,
    required this.locationFound,
    required this.foundDate,
    required this.storageLocation,
    this.status = 'IN_VAULT',
    this.images = const [],
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      locationFound: json['locationFound'] as String? ?? '',
      foundDate: json['foundDate'] != null
          ? DateTime.tryParse(json['foundDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      storageLocation: json['storageLocation'] as String? ?? '',
      status: json['status'] as String? ?? 'IN_VAULT',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toCreateDto() {
    return {
      'itemName': itemName,
      'description': description,
      'category': category,
      'locationFound': locationFound,
      'foundDate': foundDate.toIso8601String(),
      'storageLocation': storageLocation,
      'images': images,
    };
  }
}
