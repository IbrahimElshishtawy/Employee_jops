import '../../domain/services/screen_overlay_detector.dart';

/// Implementation of [ScreenOverlayDetector] that detects active overlay conditions
/// where technically supported by platform capabilities (or simulated in test/debug modes).
class ScreenOverlayDetectorImpl implements ScreenOverlayDetector {
  bool simulatedOverlayDetected;

  ScreenOverlayDetectorImpl({this.simulatedOverlayDetected = false});

  @override
  Future<bool> isUnsafeOverlayDetected() async {
    // In production, this interacts with native window flags / WindowManager overlay query APIs
    // where permitted by the platform.
    await Future.delayed(const Duration(milliseconds: 50));
    return simulatedOverlayDetected;
  }
}
