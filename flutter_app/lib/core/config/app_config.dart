class AppConfig {
  static const String appName = 'ShiftMaster Attendance';
  static const String appVersion = '1.0.0';

  // Primary deployed server endpoint (can be overridden via --dart-define or runtime settings)
  static const String defaultApiBaseUrl =
      'http://6zw5w6pyiv17takt0903hayt.51.79.133.26.sslip.io';

  // SharedPreferences storage key for dynamic runtime override
  static const String storageKeyServerUrl = 'custom_api_base_url';

  // Resolved base URL (compile-time environment variable fallback to defaultApiBaseUrl)
  static String _activeBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static String get apiBaseUrl => _activeBaseUrl;

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = cleanUrl(url);
  }

  static String cleanUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
