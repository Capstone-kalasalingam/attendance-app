import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _keyAccessToken = 'app_access_token';
  static const _keyRefreshToken = 'app_refresh_token';
  static const _keyUserData = 'app_user_data';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _useFallback = false;

  Future<void> saveTokens({required String accessToken, required String refreshToken, String? userData}) async {
    try {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      if (userData != null) {
        await _secureStorage.write(key: _keyUserData, value: userData);
      }
    } catch (e) {
      debugPrint('SecureStorage write error, using SharedPreferences fallback: $e');
      _useFallback = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
      if (userData != null) {
        await prefs.setString(_keyUserData, userData);
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    }
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    }
  }

  Future<String?> getRefreshToken() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    }
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    }
  }

  Future<String?> getUserData() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserData);
    }
    try {
      return await _secureStorage.read(key: _keyUserData);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserData);
    }
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserData);
    } catch (_) {}
  }
}
