import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/network_risk_info.dart';
import '../../domain/services/network_risk_service.dart';

/// RealNetworkRiskService inspects the active network connection for VPN or offline indicators
/// using the connectivity_plus platform APIs.
///
/// CRITICAL PRINCIPLE:
/// - VPN detection is a risk signal, NOT proof of fake location.
/// - Location verification relies primarily on GPS hardware telemetry and geofencing.
class RealNetworkRiskService implements NetworkRiskService {
  final Connectivity _connectivity;

  RealNetworkRiskService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  @override
  Future<NetworkRiskInfo> evaluateNetworkRisk() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();

      final bool isVpn = results.contains(ConnectivityResult.vpn);
      final bool isOffline = results.contains(ConnectivityResult.none) ||
          results.isEmpty;

      NetworkSecurityLevel level = NetworkSecurityLevel.normal;
      double score = 0.0;
      String? note;

      if (isVpn) {
        level = NetworkSecurityLevel.vpnDetected;
        score = 0.5;
        note = 'تم رصد شبكة VPN نشطة (إشارة أمنية)';
        SecureLogger.warn('RealNetworkRiskService', 'Active VPN detected on device');
      } else if (isOffline) {
        level = NetworkSecurityLevel.offline;
        score = 0.1;
        note = 'الجهاز غير متصل بشبكة الإنترنت';
      }

      String interfaceName = 'direct';
      if (results.contains(ConnectivityResult.wifi)) {
        interfaceName = 'wifi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        interfaceName = 'cellular';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        interfaceName = 'ethernet';
      } else if (results.contains(ConnectivityResult.vpn)) {
        interfaceName = 'vpn';
      }

      return NetworkRiskInfo(
        isVpnActive: isVpn,
        isProxyActive: false,
        isOffline: isOffline,
        interfaceName: interfaceName,
        securityLevel: level,
        riskScore: score,
        note: note,
      );
    } catch (e) {
      SecureLogger.error('RealNetworkRiskService', 'evaluateNetworkRisk error', e);
      return const NetworkRiskInfo(
        isVpnActive: false,
        isOffline: false,
        securityLevel: NetworkSecurityLevel.normal,
        riskScore: 0.0,
      );
    }
  }

  @override
  Future<bool> isVpnActive() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.vpn);
    } catch (_) {
      return false;
    }
  }
}
