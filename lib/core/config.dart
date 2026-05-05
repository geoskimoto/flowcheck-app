class AppConfig {
  // Production API — update once SSL is set up on flowcheck-api.3rdplaces.io
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8052', // Android emulator localhost alias
  );
}
