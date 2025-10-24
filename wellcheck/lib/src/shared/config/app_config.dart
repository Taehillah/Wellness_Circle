class AppConfig {
  final String apiBaseUrl;

  const AppConfig({
    required this.apiBaseUrl,
  });

  const AppConfig.fromEnvironment()
      : apiBaseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:4000',
        );

  AppConfig copyWith({String? apiBaseUrl}) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    );
  }
}
