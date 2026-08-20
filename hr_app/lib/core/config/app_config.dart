/// Environment mode enumeration for CyberWise IE
enum Environment {
  dev,
  staging,
  prod,
}

/// Global Application Configuration
class AppConfig {
  AppConfig._();

  static const String appName = 'CyberWise IE - HR Portal';
  static const String appVersion = '1.0.0';
  static const String systemId = 'CYBERWISE_HR_V1';
}
