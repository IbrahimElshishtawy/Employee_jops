import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/workplace_entity.dart';
import '../../domain/utils/geofence_math.dart';

/// Location preset for quick selection in Egypt
class LocationPreset {
  final String name;
  final double latitude;
  final double longitude;

  const LocationPreset(this.name, this.latitude, this.longitude);
}

const List<LocationPreset> kEgyptLocationPresets = [
  LocationPreset('Smart Village Campus', 30.0732, 31.0185),
  LocationPreset('New Cairo Tech Hub', 30.0280, 31.4720),
  LocationPreset('Maadi Tech Park', 29.9602, 31.2825),
  LocationPreset('Alexandria Operations Hub', 31.2001, 29.9187),
  LocationPreset('Downtown HQ Tower', 30.0444, 31.2357),
];

/// Interactive Workplace Map & Geofence Editor
class WorkplaceMapEditorWidget extends StatefulWidget {
  final GeofenceType geofenceType;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final List<GeoCoordinate> polygonPoints;
  final ValueChanged<GeoCoordinate>? onCenterChanged;
  final ValueChanged<double>? onRadiusChanged;
  final ValueChanged<List<GeoCoordinate>>? onPolygonChanged;

  const WorkplaceMapEditorWidget({
    super.key,
    required this.geofenceType,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.polygonPoints,
    this.onCenterChanged,
    this.onRadiusChanged,
    this.onPolygonChanged,
  });

  @override
  State<WorkplaceMapEditorWidget> createState() => _WorkplaceMapEditorWidgetState();
}

class _WorkplaceMapEditorWidgetState extends State<WorkplaceMapEditorWidget> {
  late double _centerLat;
  late double _centerLng;
  late double _radiusMeters;
  late List<GeoCoordinate> _polygonPoints;

  int? _selectedVertexIndex;
  double _zoomLevel = 1.0; // 0.5 to 3.0
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.centerLatitude;
    _centerLng = widget.centerLongitude;
    _radiusMeters = widget.radiusMeters;
    _polygonPoints = List<GeoCoordinate>.from(widget.polygonPoints);
  }

  @override
  void didUpdateWidget(covariant WorkplaceMapEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.centerLatitude != widget.centerLatitude || oldWidget.centerLongitude != widget.centerLongitude) {
      _centerLat = widget.centerLatitude;
      _centerLng = widget.centerLongitude;
    }
    if (oldWidget.radiusMeters != widget.radiusMeters) {
      _radiusMeters = widget.radiusMeters;
    }
    if (oldWidget.polygonPoints != widget.polygonPoints) {
      _polygonPoints = List<GeoCoordinate>.from(widget.polygonPoints);
    }
  }

  void _onMapTap(Offset localPosition, Size size) {
    final clickedCoord = _pixelToGeo(localPosition, size);

    if (widget.geofenceType == GeofenceType.circle) {
      setState(() {
        _centerLat = clickedCoord.latitude;
        _centerLng = clickedCoord.longitude;
      });
      widget.onCenterChanged?.call(clickedCoord);
    } else {
      // In polygon mode: check if clicked near existing vertex to select it, else add new point
      int clickedIndex = -1;
      for (int i = 0; i < _polygonPoints.length; i++) {
        final ptOffset = _geoToPixel(_polygonPoints[i], size);
        if ((ptOffset - localPosition).distance < 20) {
          clickedIndex = i;
          break;
        }
      }

      if (clickedIndex != -1) {
        setState(() => _selectedVertexIndex = clickedIndex);
      } else {
        setState(() {
          final newPoint = GeoCoordinate(
            latitude: clickedCoord.latitude,
            longitude: clickedCoord.longitude,
            label: 'P${_polygonPoints.length + 1}',
          );
          _polygonPoints.add(newPoint);
          _selectedVertexIndex = _polygonPoints.length - 1;

          // Update center as centroid
          final centroid = GeofenceMath.calculateCentroid(_polygonPoints);
          _centerLat = centroid.latitude;
          _centerLng = centroid.longitude;
        });
        widget.onPolygonChanged?.call(_polygonPoints);
        widget.onCenterChanged?.call(GeoCoordinate(latitude: _centerLat, longitude: _centerLng));
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_selectedVertexIndex != null && widget.geofenceType == GeofenceType.polygon) {
      final newPixel = _geoToPixel(_polygonPoints[_selectedVertexIndex!], size) + details.delta;
      final newCoord = _pixelToGeo(newPixel, size);

      setState(() {
        _polygonPoints[_selectedVertexIndex!] = GeoCoordinate(
          latitude: newCoord.latitude,
          longitude: newCoord.longitude,
          label: _polygonPoints[_selectedVertexIndex!].label ?? 'P${_selectedVertexIndex! + 1}',
        );
        final centroid = GeofenceMath.calculateCentroid(_polygonPoints);
        _centerLat = centroid.latitude;
        _centerLng = centroid.longitude;
      });
      widget.onPolygonChanged?.call(_polygonPoints);
      widget.onCenterChanged?.call(GeoCoordinate(latitude: _centerLat, longitude: _centerLng));
    } else {
      setState(() {
        _panOffset += details.delta;
      });
    }
  }

  void _removeSelectedPoint() {
    if (_selectedVertexIndex != null && _selectedVertexIndex! < _polygonPoints.length) {
      setState(() {
        _polygonPoints.removeAt(_selectedVertexIndex!);
        _selectedVertexIndex = null;
        if (_polygonPoints.isNotEmpty) {
          final centroid = GeofenceMath.calculateCentroid(_polygonPoints);
          _centerLat = centroid.latitude;
          _centerLng = centroid.longitude;
        }
      });
      widget.onPolygonChanged?.call(_polygonPoints);
      widget.onCenterChanged?.call(GeoCoordinate(latitude: _centerLat, longitude: _centerLng));
    }
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _selectedVertexIndex = null;
        if (_polygonPoints.isNotEmpty) {
          final centroid = GeofenceMath.calculateCentroid(_polygonPoints);
          _centerLat = centroid.latitude;
          _centerLng = centroid.longitude;
        }
      });
      widget.onPolygonChanged?.call(_polygonPoints);
      widget.onCenterChanged?.call(GeoCoordinate(latitude: _centerLat, longitude: _centerLng));
    }
  }

  void _clearAllPoints() {
    setState(() {
      _polygonPoints.clear();
      _selectedVertexIndex = null;
    });
    widget.onPolygonChanged?.call(_polygonPoints);
  }

  void _applyPreset(LocationPreset preset) {
    setState(() {
      _centerLat = preset.latitude;
      _centerLng = preset.longitude;
      _panOffset = Offset.zero;

      if (widget.geofenceType == GeofenceType.polygon) {
        // Create a default initial 4-point polygon around the preset
        final offset = 0.0015;
        _polygonPoints = [
          GeoCoordinate(latitude: preset.latitude + offset, longitude: preset.longitude - offset, label: 'North-West'),
          GeoCoordinate(latitude: preset.latitude + offset, longitude: preset.longitude + offset, label: 'North-East'),
          GeoCoordinate(latitude: preset.latitude - offset, longitude: preset.longitude + offset, label: 'South-East'),
          GeoCoordinate(latitude: preset.latitude - offset, longitude: preset.longitude - offset, label: 'South-West'),
        ];
        widget.onPolygonChanged?.call(_polygonPoints);
      }
    });
    widget.onCenterChanged?.call(GeoCoordinate(latitude: preset.latitude, longitude: preset.longitude));
  }

  GeoCoordinate _pixelToGeo(Offset pixel, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + _panOffset;
    const meterPerPixel = 1.0;
    final scale = meterPerPixel / _zoomLevel;

    final dxMeters = (pixel.dx - center.dx) * scale;
    final dyMeters = (pixel.dy - center.dy) * scale;

    const metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * math.cos(_centerLat * (math.pi / 180.0));

    final lat = _centerLat - (dyMeters / metersPerDegreeLat);
    final lng = _centerLng + (dxMeters / metersPerDegreeLng);

    return GeoCoordinate(latitude: lat, longitude: lng);
  }

  Offset _geoToPixel(GeoCoordinate coord, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + _panOffset;
    const metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * math.cos(_centerLat * (math.pi / 180.0));

    final dyMeters = (_centerLat - coord.latitude) * metersPerDegreeLat;
    final dxMeters = (coord.longitude - _centerLng) * metersPerDegreeLng;

    const meterPerPixel = 1.0;
    final scale = _zoomLevel / meterPerPixel;

    return center + Offset(dxMeters * scale, dyMeters * scale);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validationError = widget.geofenceType == GeofenceType.polygon
        ? GeofenceMath.validatePolygon(_polygonPoints)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Toolbar: Presets & Zoom Controls
        Row(
          children: [
            PopupMenuButton<LocationPreset>(
              tooltip: 'Quick Location Presets',
              onSelected: _applyPreset,
              itemBuilder: (context) => kEgyptLocationPresets
                  .map((p) => PopupMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Text('Egypt Hub Presets', style: AppTypography.captionBold),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            // Zoom Controls
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 20),
              tooltip: 'Zoom In',
              onPressed: () => setState(() => _zoomLevel = math.min(_zoomLevel + 0.25, 3.0)),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              tooltip: 'Zoom Out',
              onPressed: () => setState(() => _zoomLevel = math.max(_zoomLevel - 0.25, 0.4)),
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 20),
              tooltip: 'Reset View',
              onPressed: () => setState(() {
                _panOffset = Offset.zero;
                _zoomLevel = 1.0;
              }),
            ),
            const Spacer(),
            if (widget.geofenceType == GeofenceType.polygon) ...[
              if (_selectedVertexIndex != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.errorLight),
                  label: Text('Delete Point P${_selectedVertexIndex! + 1}', style: const TextStyle(color: AppColors.errorLight)),
                  onPressed: _removeSelectedPoint,
                ),
              TextButton.icon(
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo Point'),
                onPressed: _polygonPoints.isNotEmpty ? _undoLastPoint : null,
              ),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 16, color: AppColors.textSecondaryLight),
                label: const Text('Clear All'),
                onPressed: _polygonPoints.isNotEmpty ? _clearAllPoints : null,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.space8),

        // Interactive Map Canvas Area
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              border: Border.all(
                color: validationError != null
                    ? AppColors.errorLight
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: validationError != null ? 2 : 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    // Canvas GestureDetector
                    GestureDetector(
                      onTapUp: (details) => _onMapTap(details.localPosition, size),
                      onPanUpdate: (details) => _onPanUpdate(details, size),
                      onPanEnd: (_) => setState(() => _selectedVertexIndex = null),
                      child: CustomPaint(
                        size: size,
                        painter: _MapCanvasPainter(
                          geofenceType: widget.geofenceType,
                          centerCoord: GeoCoordinate(latitude: _centerLat, longitude: _centerLng),
                          radiusMeters: _radiusMeters,
                          polygonPoints: _polygonPoints,
                          selectedVertexIndex: _selectedVertexIndex,
                          zoomLevel: _zoomLevel,
                          panOffset: _panOffset,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Canvas Overlay Instructions
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.geofenceType == GeofenceType.polygon
                                  ? Icons.touch_app_outlined
                                  : Icons.gps_fixed,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.geofenceType == GeofenceType.polygon
                                  ? 'Click map to place points. Drag points to adjust.'
                                  : 'Click map to set center location.',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Validation & Stats Overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: validationError != null
                              ? AppColors.errorLight.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              validationError != null ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              validationError ??
                                  (widget.geofenceType == GeofenceType.polygon
                                      ? 'Valid Boundary • ${_polygonPoints.length} Points • ~${GeofenceMath.calculateAreaSquareMeters(_polygonPoints).toInt()} m²'
                                      : 'Radius: ${_radiusMeters.toInt()}m • Area: ~${(math.pi * _radiusMeters * _radiusMeters).toInt()} m²'),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Coordinates Readout
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Center: ${_centerLat.toStringAsFixed(5)}, ${_centerLng.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
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

        // Controls Section below Canvas
        if (widget.geofenceType == GeofenceType.circle) ...[
          Row(
            children: [
              Text('Allowed Radius: ${_radiusMeters.toInt()} meters', style: AppTypography.bodyBold),
              const Spacer(),
              SizedBox(
                width: 120,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Radius (m)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _radiusMeters.toInt().toString())
                    ..selection = TextSelection.collapsed(offset: _radiusMeters.toInt().toString().length),
                  onSubmitted: (val) {
                    final d = double.tryParse(val);
                    if (d != null && d > 0) {
                      setState(() => _radiusMeters = d);
                      widget.onRadiusChanged?.call(d);
                    }
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: _radiusMeters.clamp(10.0, 1000.0),
            min: 10.0,
            max: 1000.0,
            divisions: 99,
            activeColor: AppColors.primaryLight,
            label: '${_radiusMeters.toInt()} m',
            onChanged: (val) {
              setState(() => _radiusMeters = val);
              widget.onRadiusChanged?.call(val);
            },
          ),
        ] else ...[
          // Polygon Vertex Summary List
          if (_polygonPoints.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _polygonPoints.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final pt = _polygonPoints[idx];
                  final isSelected = _selectedVertexIndex == idx;
                  return ChoiceChip(
                    label: Text('${pt.label ?? 'P${idx + 1}'} (${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)})'),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                    onSelected: (selected) {
                      setState(() => _selectedVertexIndex = selected ? idx : null);
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

/// Custom Canvas Painter rendering coordinates, grid, polygon, vertices, and radius circle
class _MapCanvasPainter extends CustomPainter {
  final GeofenceType geofenceType;
  final GeoCoordinate centerCoord;
  final double radiusMeters;
  final List<GeoCoordinate> polygonPoints;
  final int? selectedVertexIndex;
  final double zoomLevel;
  final Offset panOffset;
  final bool isDark;

  _MapCanvasPainter({
    required this.geofenceType,
    required this.centerCoord,
    required this.radiusMeters,
    required this.polygonPoints,
    required this.selectedVertexIndex,
    required this.zoomLevel,
    required this.panOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPixel = Offset(size.width / 2, size.height / 2) + panOffset;

    // 1. Draw Grid Lines (Blueprint map aesthetic)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    final startX = (centerPixel.dx % gridSize) - gridSize;
    final startY = (centerPixel.dy % gridSize) - gridSize;

    for (double x = startX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = startY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Crosshairs at Center
    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(centerPixel.dx - 12, centerPixel.dy), Offset(centerPixel.dx + 12, centerPixel.dy), crosshairPaint);
    canvas.drawLine(Offset(centerPixel.dx, centerPixel.dy - 12), Offset(centerPixel.dx, centerPixel.dy + 12), crosshairPaint);

    if (geofenceType == GeofenceType.circle) {
      // Draw Circular Geofence
      const meterPerPixel = 1.0;
      final pixelRadius = radiusMeters * (zoomLevel / meterPerPixel);

      // Fill
      final fillPaint = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerPixel, pixelRadius, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(centerPixel, pixelRadius, strokePaint);

      // Center Pin
      final pinPaint = Paint()..color = AppColors.primaryLight;
      canvas.drawCircle(centerPixel, 7, pinPaint);
      canvas.drawCircle(centerPixel, 3, Paint()..color = Colors.white);
    } else {
      // Draw Polygon Geofence
      if (polygonPoints.isNotEmpty) {
        final pixelPoints = polygonPoints.map((p) => _geoToPixel(p, size, centerPixel)).toList();

        // If >= 3 points, draw shaded interior
        if (pixelPoints.length >= 3) {
          final path = Path();
          path.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
          for (int i = 1; i < pixelPoints.length; i++) {
            path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
          }
          path.close();

          final fillPaint = Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: 0.20)
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, fillPaint);

          final strokePaint = Paint()
            ..color = const Color(0xFF10B981)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(path, strokePaint);
        } else if (pixelPoints.length == 2) {
          // Draw single line segment between 2 points
          final linePaint = Paint()
            ..color = const Color(0xFF10B981)
            ..strokeWidth = 2.5;
          canvas.drawLine(pixelPoints[0], pixelPoints[1], linePaint);
        }

        // Draw Vertices and Labels
        for (int i = 0; i < pixelPoints.length; i++) {
          final pt = pixelPoints[i];
          final isSelected = selectedVertexIndex == i;

          // Vertex outer glow / selection halo
          if (isSelected) {
            canvas.drawCircle(pt, 14, Paint()..color = Colors.amber.withValues(alpha: 0.4));
          }

          // Vertex Point
          final vertexPaint = Paint()..color = isSelected ? Colors.amber : const Color(0xFF10B981);
          canvas.drawCircle(pt, 8, vertexPaint);
          canvas.drawCircle(pt, 4, Paint()..color = Colors.white);

          // Point Label text (P1, P2...)
          final textPainter = TextPainter(
            text: TextSpan(
              text: 'P${i + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(canvas, Offset(pt.dx + 10, pt.dy - 16));
        }
      }
    }
  }

  Offset _geoToPixel(GeoCoordinate coord, Size size, Offset centerPixel) {
    const metersPerDegreeLat = 111132.92;
    final metersPerDegreeLng = 111412.84 * math.cos(centerCoord.latitude * (math.pi / 180.0));

    final dyMeters = (centerCoord.latitude - coord.latitude) * metersPerDegreeLat;
    final dxMeters = (coord.longitude - centerCoord.longitude) * metersPerDegreeLng;

    const meterPerPixel = 1.0;
    final scale = zoomLevel / meterPerPixel;

    return centerPixel + Offset(dxMeters * scale, dyMeters * scale);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.geofenceType != geofenceType ||
        oldDelegate.centerCoord != centerCoord ||
        oldDelegate.radiusMeters != radiusMeters ||
        oldDelegate.polygonPoints != polygonPoints ||
        oldDelegate.selectedVertexIndex != selectedVertexIndex ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.panOffset != panOffset;
  }
}
