import '../models/company.dart';

/// The single canonical company location used for geofence validation.
class CompanySeed {
  static const String companyId = 'COMP-001';
  static const String locationId = 'LOC-001';

  static Company get company => const Company(
        id: companyId,
        name: 'CyberWise IE',
        address: 'Cairo, Egypt',
        city: 'Cairo',
        country: 'Egypt',
      );

  /// Company HQ — employees must be within [radiusMeters] to check in/out.
  static CompanyLocation get location => const CompanyLocation(
        id: locationId,
        label: 'CyberWise IE - Test Office',
        latitude: 30.044400,
        longitude: 31.235700,
        radiusMeters: 4.0,
      );
}
