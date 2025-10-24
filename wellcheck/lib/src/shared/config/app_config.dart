import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

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

  factory AppConfig.auto() {
    final env = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) {
      return AppConfig(apiBaseUrl: env);
    }
    if (kIsWeb) {
      return const AppConfig(apiBaseUrl: 'http://localhost:4000');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulators cannot reach host 127.0.0.1; use the special bridge address.
      return const AppConfig(apiBaseUrl: 'http://10.0.2.2:4000');
    }
    return const AppConfig(apiBaseUrl: 'http://localhost:4000');
  }

  AppConfig copyWith({String? apiBaseUrl}) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    );
  }
}
