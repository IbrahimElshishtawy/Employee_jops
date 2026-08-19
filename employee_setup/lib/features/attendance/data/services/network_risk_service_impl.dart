import '../../domain/models/network_risk_info.dart';
import '../../domain/services/network_risk_service.dart';

/// Concrete implementation of NetworkRiskService.
/// Gathers network risk indicators (VPN, Proxy, Latency).
class NetworkRiskServiceImpl implements NetworkRiskService {
  bool simulatedVpnActive;
  bool simulatedProxyActive;

  NetworkRiskServiceImpl({
    this.simulatedVpnActive = false,
    this.simulatedProxyActive = false,
  });

  @override
  Future<NetworkRiskInfo> evaluateNetworkRisk() async {
    await Future.delayed(const Duration(milliseconds: 50));

    final isVpn = simulatedVpnActive;
    final isProxy = simulatedProxyActive;

    NetworkSecurityLevel level = NetworkSecurityLevel.normal;
    double riskScore = 0.0;

    if (isVpn) {
      level = NetworkSecurityLevel.vpnDetected;
      riskScore = 0.35; // Moderate risk indicator (not automatic rejection)
    } else if (isProxy) {
      level = NetworkSecurityLevel.proxyDetected;
      riskScore = 0.45;
    }

    return NetworkRiskInfo(
      isVpnActive: isVpn,
      isProxyActive: isProxy,
      isOffline: false,
      ipAddress: '192.168.1.100',
      interfaceName: isVpn ? 'tun0' : 'wlan0',
      securityLevel: level,
      riskScore: riskScore,
      note: isVpn ? 'VPN interface active' : null,
    );
  }

  @override
  Future<bool> isVpnActive() async {
    return simulatedVpnActive;
  }
}
