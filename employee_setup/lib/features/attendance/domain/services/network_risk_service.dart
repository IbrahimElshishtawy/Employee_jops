import '../models/network_risk_info.dart';

/// NetworkRiskService inspects the active network environment for risk signals
/// (VPN active, HTTP proxy, mock network).
///
/// NOTE: VPN detection is a risk signal, NOT proof of fake location.
/// GPS location remains the primary geographic proof.
abstract class NetworkRiskService {
  /// Evaluates current network risk and returns a [NetworkRiskInfo] report.
  Future<NetworkRiskInfo> evaluateNetworkRisk();

  /// Quick check whether a VPN is currently active on the device.
  Future<bool> isVpnActive();
}
