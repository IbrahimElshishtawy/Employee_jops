enum NetworkSecurityLevel {
  normal,
  vpnDetected,
  proxyDetected,
  mockNetwork,
  offline,
  suspicious,
}

/// Network and VPN risk telemetry.
/// IMPORTANT: VPN detection is NOT proof of fake GPS. It is a security/risk signal
/// sent to the backend to help make risk-informed decisions.
class NetworkRiskInfo {
  final bool isVpnActive;
  final bool isProxyActive;
  final bool isOffline;
  final String? ipAddress;
  final String? interfaceName;
  final NetworkSecurityLevel securityLevel;
  final double riskScore; // 0.0 (clean) to 1.0 (high risk)
  final String? note;

  const NetworkRiskInfo({
    this.isVpnActive = false,
    this.isProxyActive = false,
    this.isOffline = false,
    this.ipAddress,
    this.interfaceName,
    this.securityLevel = NetworkSecurityLevel.normal,
    this.riskScore = 0.0,
    this.note,
  });

  bool get hasRisk => isVpnActive || isProxyActive || riskScore > 0.4;

  Map<String, dynamic> toJson() => {
    'isVpnActive': isVpnActive,
    'isProxyActive': isProxyActive,
    'isOffline': isOffline,
    'ipAddress': ipAddress,
    'interfaceName': interfaceName,
    'securityLevel': securityLevel.name,
    'riskScore': riskScore,
    'note': note,
  };

  factory NetworkRiskInfo.fromJson(Map<String, dynamic> json) =>
      NetworkRiskInfo(
        isVpnActive: json['isVpnActive'] as bool? ?? false,
        isProxyActive: json['isProxyActive'] as bool? ?? false,
        isOffline: json['isOffline'] as bool? ?? false,
        ipAddress: json['ipAddress'] as String?,
        interfaceName: json['interfaceName'] as String?,
        securityLevel: NetworkSecurityLevel.values.byName(
          json['securityLevel'] as String? ?? 'normal',
        ),
        riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
        note: json['note'] as String?,
      );
}
