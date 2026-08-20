import 'app_config.dart';

/// Environment-specific configuration
class EnvConfig {
  static Environment currentEnvironment = Environment.dev;

  static void initialize({Environment environment = Environment.dev}) {
    currentEnvironment = environment;
  }

  static bool get isDev => currentEnvironment == Environment.dev;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isProd => currentEnvironment == Environment.prod;

  /// Authoritative backend API Base URL
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'https://api-dev.cyberwise.internal/api/v1';
      case Environment.staging:
        return 'https://api-staging.cyberwise.internal/api/v1';
      case Environment.prod:
        return 'https://api.cyberwise.internal/api/v1';
    }
  }

  /// Flag to enable Mock Data for local frontend development.
  /// Strictly disabled in Production.
  static bool get enableMockData {
    if (isProd) return false;
    return true; // Set to false to switch to live backend API during dev/staging
  }

  /// Flag for sanitized debug logging
  static bool get enableDebugLogging => !isProd;
}
