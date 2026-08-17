// ============================================================
// Company & CompanyLocation Models
// ============================================================

class Company {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;

  const Company({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'country': country,
      };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
      );
}

/// Physical location of the company office used for geofence validation.
class CompanyLocation {
  final String id;
  final String label;
  final double latitude;
  final double longitude;

  /// Maximum allowed distance in meters for attendance check-in/out.
  final double radiusMeters;

  const CompanyLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };

  factory CompanyLocation.fromJson(Map<String, dynamic> json) => CompanyLocation(
        id: json['id'] as String,
        label: json['label'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
      );
}
