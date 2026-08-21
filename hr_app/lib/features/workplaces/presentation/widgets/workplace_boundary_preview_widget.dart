import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../domain/entities/workplace_entity.dart';
import '../../domain/utils/geofence_math.dart';

/// Visual Boundary Preview Widget with Interactive Attendance Geofence Simulator
class WorkplaceBoundaryPreviewWidget extends StatefulWidget {
  final WorkplaceEntity workplace;

  const WorkplaceBoundaryPreviewWidget({super.key, required this.workplace});

  @override
  State<WorkplaceBoundaryPreviewWidget> createState() => _WorkplaceBoundaryPreviewWidgetState();
}

class _WorkplaceBoundaryPreviewWidgetState extends State<WorkplaceBoundaryPreviewWidget> {
  GeoCoordinate? _simulatedPoint;
  bool? _isInsideGeofence;
  double? _distanceFromCenter;

  @override
  void initState() {
    super.initState();
    // Default simulated point near center
    _simulatedPoint = GeoCoordinate(
      latitude: widget.workplace.latitude + 0.0003,
      longitude: widget.workplace.longitude + 0.0003,
    );
    _evaluateSimulation();
  }

  void _evaluateSimulation() {
    if (_simulatedPoint == null) return;

    if (widget.workplace.geofenceType == GeofenceType.polygon) {
      _isInsideGeofence = GeofenceMath.isPointInPolygon(
        _simulatedPoint!,
        widget.workplace.polygonPoints,
      );
    } else {
      _isInsideGeofence = GeofenceMath.isPointInCircle(
        _simulatedPoint!,
        GeoCoordinate(
          latitude: widget.workplace.latitude,
          longitude: widget.workplace.longitude,
        ),
        widget.workplace.allowedRadiusMeters,
      );
    }

    _distanceFromCenter = GeofenceMath.calculateDistanceMeters(
      _simulatedPoint!,
      GeoCoordinate(
        latitude: widget.workplace.latitude,
        longitude: widget.workplace.longitude,
      ),
    );
  }

  void _onCanvasTap(Offset localPosition, Size size) {
    final centerPixel = Offset(size.width / 2, size.height / 2);
    const meterPerPixel = 1.0;
    const zoomLevel = 1.2;
    final scale = meterPerPixel / zoomLevel;

    final dxMeters = (localPosition.dx - centerPixel.dx) * scale;
    final dyMeters = (localPosition.dy - centerPixel.dy) * scale;

    const metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * math.cos(widget.workplace.latitude * (math.pi / 180.0));

    final lat = widget.workplace.latitude - (dyMeters / metersPerDegreeLat);
    final lng = widget.workplace.longitude + (dxMeters / metersPerDegreeLng);

    setState(() {
      _simulatedPoint = GeoCoordinate(latitude: lat, longitude: lng);
      _evaluateSimulation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wp = widget.workplace;

    final areaMeters = wp.geofenceType == GeofenceType.polygon
        ? GeofenceMath.calculateAreaSquareMeters(wp.polygonPoints)
        : math.pi * wp.allowedRadiusMeters * wp.allowedRadiusMeters;

    final perimeterMeters = wp.geofenceType == GeofenceType.polygon
        ? GeofenceMath.calculatePerimeterMeters(wp.polygonPoints)
        : 2 * math.pi * wp.allowedRadiusMeters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boundary Canvas
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (details) => _onCanvasTap(details.localPosition, size),
                      child: CustomPaint(
                        size: size,
                        painter: _BoundaryPreviewPainter(
                          workplace: wp,
                          simulatedPoint: _simulatedPoint,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          'Click canvas to simulate employee punch position',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space12),

        // Live Simulation Result Card
        if (_simulatedPoint != null)
          Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: _isInsideGeofence == true
                  ? (isDark ? AppColors.successBgDark : AppColors.success.withValues(alpha: 0.12))
                  : (isDark ? AppColors.dangerBgDark : AppColors.danger.withValues(alpha: 0.12)),
              border: Border.all(
                color: _isInsideGeofence == true
                    ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                    : (isDark ? const Color(0xFFF87171) : AppColors.danger),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  _isInsideGeofence == true ? Icons.verified_outlined : Icons.gpp_bad_outlined,
                  color: _isInsideGeofence == true
                      ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                      : (isDark ? const Color(0xFFF87171) : AppColors.danger),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInsideGeofence == true
                            ? 'PUNCH PERMITTED — Inside Boundary'
                            : 'PUNCH REJECTED — Outside Boundary',
                        style: AppTypography.bodyBold.copyWith(
                          color: _isInsideGeofence == true
                              ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                              : (isDark ? const Color(0xFFF87171) : AppColors.danger),
                        ),
                      ),
                      Text(
                        'Simulated GPS: ${_simulatedPoint!.latitude.toStringAsFixed(5)}, ${_simulatedPoint!.longitude.toStringAsFixed(5)} (${_distanceFromCenter?.toInt()}m from center)',
                        style: AppTypography.captionOf(context),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: _isInsideGeofence == true ? 'Authorized' : 'Prohibited',
                  variant: _isInsideGeofence == true ? BadgeVariant.success : BadgeVariant.danger,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.space12),

        // Specs Grid
        Container(
          padding: const EdgeInsets.all(AppDimensions.space12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildSpecRow(context, 'Geofence Model', wp.geofenceType.label),
              _buildSpecRow(
                context,
                wp.geofenceType == GeofenceType.polygon ? 'Polygon Vertices' : 'Allowed Radius',
                wp.geofenceType == GeofenceType.polygon
                    ? '${wp.polygonPoints.length} GPS Coordinates'
                    : '${wp.allowedRadiusMeters.toInt()} meters',
              ),
              _buildSpecRow(context, 'Boundary Area', '~${areaMeters.toInt()} m²'),
              _buildSpecRow(context, 'Perimeter', '~${perimeterMeters.toInt()} m'),
              _buildSpecRow(context, 'Assigned Staff', '${wp.assignedEmployeesCount} active employees'),
              _buildSpecRow(
                context,
                'Status',
                wp.isActive ? 'Active & Authoritative' : 'Inactive (Punches Blocked)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.captionBold),
          Text(value, style: AppTypography.captionOf(context)),
        ],
      ),
    );
  }
}

class _BoundaryPreviewPainter extends CustomPainter {
  final WorkplaceEntity workplace;
  final GeoCoordinate? simulatedPoint;
  final bool isDark;

  _BoundaryPreviewPainter({
    required this.workplace,
    this.simulatedPoint,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPixel = Offset(size.width / 2, size.height / 2);
    const zoomLevel = 1.2;

    // Grid
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F172A).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (workplace.geofenceType == GeofenceType.circle) {
      final pixelRadius = workplace.allowedRadiusMeters * (zoomLevel / 1.0);
      final fillPaint = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerPixel, pixelRadius, fillPaint);

      final strokePaint = Paint()
        ..color = isDark ? AppColors.primaryLight : AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(centerPixel, pixelRadius, strokePaint);

      // Center
      canvas.drawCircle(centerPixel, 5, Paint()..color = isDark ? AppColors.primaryLight : AppColors.primary);
    } else {
      if (workplace.polygonPoints.length >= 3) {
        final pixelPoints = workplace.polygonPoints
            .map((p) => _geoToPixel(p, workplace.latitude, workplace.longitude, centerPixel, zoomLevel))
            .toList();

        final path = Path();
        path.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
        for (int i = 1; i < pixelPoints.length; i++) {
          path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
        }
        path.close();

        final fillPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.18)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        final strokePaint = Paint()
          ..color = isDark ? const Color(0xFF10B981) : const Color(0xFF059669)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawPath(path, strokePaint);

        for (final pt in pixelPoints) {
          canvas.drawCircle(pt, 5, Paint()..color = isDark ? const Color(0xFF10B981) : const Color(0xFF059669));
          canvas.drawCircle(pt, 2, Paint()..color = Colors.white);
        }
      }
    }

    // Draw Simulated Employee Punch Location
    if (simulatedPoint != null) {
      final simPixel = _geoToPixel(
        simulatedPoint!,
        workplace.latitude,
        workplace.longitude,
        centerPixel,
        zoomLevel,
      );

      final pulsePaint = Paint()
        ..color = (isDark ? Colors.cyanAccent : const Color(0xFF0284C7)).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(simPixel, 12, pulsePaint);

      final simPaint = Paint()..color = isDark ? Colors.cyanAccent : const Color(0xFF0284C7);
      canvas.drawCircle(simPixel, 6, simPaint);
      canvas.drawCircle(simPixel, 2, Paint()..color = Colors.white);
    }
  }

  Offset _geoToPixel(
    GeoCoordinate coord,
    double centerLat,
    double centerLng,
    Offset centerPixel,
    double zoomLevel,
  ) {
    const metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * math.cos(centerLat * (math.pi / 180.0));

    final dyMeters = (centerLat - coord.latitude) * metersPerDegreeLat;
    final dxMeters = (coord.longitude - centerLng) * metersPerDegreeLng;

    const meterPerPixel = 1.0;
    final scale = zoomLevel / meterPerPixel;

    return centerPixel + Offset(dxMeters * scale, dyMeters * scale);
  }

  @override
  bool shouldRepaint(covariant _BoundaryPreviewPainter oldDelegate) {
    return oldDelegate.workplace != workplace ||
        oldDelegate.simulatedPoint != simulatedPoint ||
        oldDelegate.isDark != isDark;
  }
}
