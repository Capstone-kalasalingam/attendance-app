import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Glassmorphic Attendance';
  static const String appVersion = '1.0.0';

  // Base URL can be configured at compile time using:
  // flutter run --dart-define=API_BASE_URL=https://your-api.com
  static String get apiBaseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    // Android emulator alias for host machine
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    // macOS, iOS simulator, Windows, Linux
    return 'http://localhost:8080';
  }
}
