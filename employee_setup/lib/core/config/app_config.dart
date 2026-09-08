import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool enableNetworkLogs;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.enableNetworkLogs = true,
  });

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;

  /// Resolves the default development host: 10.0.2.2 for Android emulator, localhost for others.
  static String get _defaultDevHost {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  static AppConfig development = AppConfig(
    environment: AppEnvironment.development,
    appName: 'CyberWise Employee (Dev)',
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    ).isNotEmpty
        ? const String.fromEnvironment('API_BASE_URL')
        : _defaultDevHost,
    enableNetworkLogs: true,
  );

  static const AppConfig staging = AppConfig(
    environment: AppEnvironment.staging,
    appName: 'CyberWise Employee (Staging)',
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://staging.cyberwise.hotel/api/v1',
    ),
    enableNetworkLogs: true,
  );

  static const AppConfig production = AppConfig(
    environment: AppEnvironment.production,
    appName: 'CyberWise Employee',
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.cyberwise.hotel/api/v1',
    ),
    enableNetworkLogs: false,
  );

  static AppConfig current = development;
}
