/// Domain contract for detecting screen overlay risks (e.g., DRAW_OVER_OTHER_APPS on Android)
/// during high-security attendance check-in operations.
abstract class ScreenOverlayDetector {
  /// Returns true if an untrusted or suspicious window/overlay is detected
  /// that might intercept user touch events or spoof UI elements.
  Future<bool> isUnsafeOverlayDetected();
}
