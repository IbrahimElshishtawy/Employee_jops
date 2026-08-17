class AppConfig {
  final String appName;
  final String apiBaseUrl;
  final bool isProduction;

  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.isProduction,
  });

  static const AppConfig development = AppConfig(
    appName: 'Employee App (Dev)',
    apiBaseUrl: 'https://mock.api.company.local',
    isProduction: false,
  );
}
