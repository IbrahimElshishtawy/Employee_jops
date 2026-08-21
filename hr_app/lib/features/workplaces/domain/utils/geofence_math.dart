import 'dart:math' as math;
import '../entities/workplace_entity.dart';

/// Geometry and Geofence mathematical utilities for CyberWise IE
class GeofenceMath {
  GeofenceMath._();

  /// Earth radius in meters (WGS-84 mean radius)
  static const double earthRadiusMeters = 6371000.0;

  /// Calculate distance in meters between two geographic coordinates using the Haversine formula
  static double calculateDistanceMeters(GeoCoordinate p1, GeoCoordinate p2) {
    final dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final dLon = _degreesToRadians(p2.longitude - p1.longitude);

    final lat1 = _degreesToRadians(p1.latitude);
    final lat2 = _degreesToRadians(p2.latitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Check if a point is within a circular geofence
  static bool isPointInCircle(GeoCoordinate point, GeoCoordinate center, double radiusMeters) {
    final distance = calculateDistanceMeters(point, center);
    return distance <= radiusMeters;
  }

  /// Ray-Casting algorithm to determine if a point is inside an arbitrary polygon
  /// Returns true if [point] is strictly inside or on the boundary of [polygon]
  static bool isPointInPolygon(GeoCoordinate point, List<GeoCoordinate> polygon) {
    if (polygon.length < 3) return false;

    bool isInside = false;
    final n = polygon.length;
    final px = point.longitude;
    final py = point.latitude;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      // Check if point is exactly on vertex
      if ((xi == px && yi == py) || (xj == px && yj == py)) {
        return true;
      }

      // Check if ray crosses edge
      final intersect = ((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi);

      if (intersect) {
        isInside = !isInside;
      }
    }

    return isInside;
  }

  /// Compute the geometric centroid (center of mass) of a polygon
  static GeoCoordinate calculateCentroid(List<GeoCoordinate> points) {
    if (points.isEmpty) return const GeoCoordinate(latitude: 0, longitude: 0);
    if (points.length == 1) return points.first;

    double sumLat = 0;
    double sumLng = 0;

    for (final p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }

    return GeoCoordinate(
      latitude: sumLat / points.length,
      longitude: sumLng / points.length,
    );
  }

  /// Calculate total perimeter in meters of a closed polygon
  static double calculatePerimeterMeters(List<GeoCoordinate> points) {
    if (points.length < 2) return 0.0;

    double totalPerimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final nextIndex = (i + 1) % points.length;
      totalPerimeter += calculateDistanceMeters(points[i], points[nextIndex]);
    }
    return totalPerimeter;
  }

  /// Calculate approximate planar area in square meters for a closed geographic polygon
  static double calculateAreaSquareMeters(List<GeoCoordinate> points) {
    if (points.length < 3) return 0.0;

    // Approximate area using spherical projection on tangent plane at centroid
    final centroid = calculateCentroid(points);
    final latRad = _degreesToRadians(centroid.latitude);
    final metersPerDegLat = 111132.92 - 559.82 * math.cos(2 * latRad) + 1.175 * math.cos(4 * latRad);
    final metersPerDegLng = 111412.84 * math.cos(latRad) - 93.5 * math.cos(3 * latRad);

    double area = 0.0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final xi = (points[i].longitude - centroid.longitude) * metersPerDegLng;
      final yi = (points[i].latitude - centroid.latitude) * metersPerDegLat;
      final xj = (points[j].longitude - centroid.longitude) * metersPerDegLng;
      final yj = (points[j].latitude - centroid.latitude) * metersPerDegLat;

      area += (xi * yj) - (xj * yi);
    }

    return (area.abs()) / 2.0;
  }

  /// Validate polygon geometry
  /// Returns null if valid, or a descriptive error message if invalid
  static String? validatePolygon(List<GeoCoordinate> points) {
    if (points.length < 3) {
      return 'A polygon requires at least 3 points to form a closed boundary.';
    }

    // Check for duplicate consecutive points
    for (int i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      if ((points[i].latitude - points[next].latitude).abs() < 1e-7 &&
          (points[i].longitude - points[next].longitude).abs() < 1e-7) {
        return 'Polygon contains duplicate consecutive vertices.';
      }
    }

    // Check for self-intersecting segments
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final a1 = points[i];
      final a2 = points[(i + 1) % n];

      for (int j = i + 2; j < n; j++) {
        // Exclude adjacent segments sharing a vertex
        if ((i == 0 && j == n - 1)) continue;

        final b1 = points[j];
        final b2 = points[(j + 1) % n];

        if (_segmentsIntersect(a1, a2, b1, b2)) {
          return 'Polygon edges intersect. Boundaries must form a simple, non-self-intersecting shape.';
        }
      }
    }

    return null;
  }

  /// Check if line segment (p1-p2) intersects with segment (p3-p4)
  static bool _segmentsIntersect(
    GeoCoordinate p1,
    GeoCoordinate p2,
    GeoCoordinate p3,
    GeoCoordinate p4,
  ) {
    final d1 = _ccw(p1, p3, p4);
    final d2 = _ccw(p2, p3, p4);
    final d3 = _ccw(p1, p2, p3);
    final d4 = _ccw(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    return false;
  }

  static double _ccw(GeoCoordinate a, GeoCoordinate b, GeoCoordinate c) {
    return (b.longitude - a.longitude) * (c.latitude - a.latitude) -
        (b.latitude - a.latitude) * (c.longitude - a.longitude);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
