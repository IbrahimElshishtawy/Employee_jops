import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/features/workplaces/domain/entities/workplace_entity.dart';
import 'package:hr_app/features/workplaces/domain/utils/geofence_math.dart';

void main() {
  group('GeofenceMath Tests', () {
    // Convex polygon (Smart Village bounding box)
    final smartVillagePolygon = [
      const GeoCoordinate(latitude: 30.0750, longitude: 31.0170, label: 'NW'),
      const GeoCoordinate(latitude: 30.0750, longitude: 31.0200, label: 'NE'),
      const GeoCoordinate(latitude: 30.0715, longitude: 31.0200, label: 'SE'),
      const GeoCoordinate(latitude: 30.0715, longitude: 31.0170, label: 'SW'),
    ];

    test('isPointInPolygon returns true for point inside polygon', () {
      const insidePoint = GeoCoordinate(latitude: 30.0730, longitude: 31.0185);
      final result = GeofenceMath.isPointInPolygon(insidePoint, smartVillagePolygon);
      expect(result, isTrue);
    });

    test('isPointInPolygon returns false for point outside polygon', () {
      const outsidePoint = GeoCoordinate(latitude: 30.0800, longitude: 31.0250);
      final result = GeofenceMath.isPointInPolygon(outsidePoint, smartVillagePolygon);
      expect(result, isFalse);
    });

    test('isPointInCircle correctly checks radius boundary', () {
      const center = GeoCoordinate(latitude: 30.0444, longitude: 31.2357);
      // Close point (~50m away)
      const nearPoint = GeoCoordinate(latitude: 30.0447, longitude: 31.2357);
      // Far point (~500m away)
      const farPoint = GeoCoordinate(latitude: 30.0490, longitude: 31.2357);

      expect(GeofenceMath.isPointInCircle(nearPoint, center, 100.0), isTrue);
      expect(GeofenceMath.isPointInCircle(farPoint, center, 100.0), isFalse);
    });

    test('calculateCentroid computes correct average coordinate', () {
      final centroid = GeofenceMath.calculateCentroid(smartVillagePolygon);
      expect(centroid.latitude, closeTo(30.07325, 0.001));
      expect(centroid.longitude, closeTo(31.0185, 0.001));
    });

    test('validatePolygon rejects polygon with less than 3 points', () {
      final twoPoints = [
        const GeoCoordinate(latitude: 30.0, longitude: 31.0),
        const GeoCoordinate(latitude: 30.1, longitude: 31.1),
      ];
      expect(GeofenceMath.validatePolygon(twoPoints), isNotNull);
    });

    test('validatePolygon accepts valid closed non-intersecting polygon', () {
      expect(GeofenceMath.validatePolygon(smartVillagePolygon), isNull);
    });

    test('validatePolygon rejects self-intersecting bowtie polygon', () {
      final bowtiePolygon = [
        const GeoCoordinate(latitude: 30.0, longitude: 31.0),
        const GeoCoordinate(latitude: 30.1, longitude: 31.1),
        const GeoCoordinate(latitude: 30.1, longitude: 31.0),
        const GeoCoordinate(latitude: 30.0, longitude: 31.1),
      ];
      final error = GeofenceMath.validatePolygon(bowtiePolygon);
      expect(error, contains('intersect'));
    });

    test('calculateAreaSquareMeters returns reasonable area for polygon', () {
      final area = GeofenceMath.calculateAreaSquareMeters(smartVillagePolygon);
      expect(area, greaterThan(10000));
    });
  });
}
