import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/token_manager.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ApiBaseUrlNotifier extends StateNotifier<String> {
  ApiBaseUrlNotifier() : super(AppConfig.apiBaseUrl) {
    _loadPersistedUrl();
  }

  Future<void> _loadPersistedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(AppConfig.storageKeyServerUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        final cleaned = AppConfig.cleanUrl(savedUrl);
        AppConfig.setActiveBaseUrl(cleaned);
        state = cleaned;
      }
    } catch (e) {
      debugPrint('Could not load saved server URL: $e');
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    final cleaned = AppConfig.cleanUrl(newUrl);
    AppConfig.setActiveBaseUrl(cleaned);
    state = cleaned;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.storageKeyServerUrl, cleaned);
    } catch (e) {
      debugPrint('Could not save custom server URL: $e');
    }
  }

  Future<void> resetToDefault() async {
    AppConfig.setActiveBaseUrl(AppConfig.defaultApiBaseUrl);
    state = AppConfig.defaultApiBaseUrl;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.storageKeyServerUrl);
    } catch (e) {
      debugPrint('Could not remove custom server URL: $e');
    }
  }
}

final apiBaseUrlProvider = StateNotifierProvider<ApiBaseUrlNotifier, String>((ref) {
  return ApiBaseUrlNotifier();
});

final tokenManagerProvider = Provider<TokenManager>((ref) => TokenManager());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(tokenManager: tokenManager, baseUrl: baseUrl);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthNotifier(apiClient: apiClient, tokenManager: tokenManager);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  AuthNotifier({required this.apiClient, required this.tokenManager})
      : super(const AuthState()) {
    apiClient.onSessionExpired = handleSessionExpired;
    checkSession();
  }

  Future<void> checkSession() async {
    final token = await tokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final cachedUserJson = await tokenManager.getUserData();
    UserModel? cachedUser;
    if (cachedUserJson != null) {
      try {
        cachedUser = UserModel.fromJson(jsonDecode(cachedUserJson));
      } catch (_) {}
    }

    if (cachedUser != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: cachedUser);
    }

    // Verify token with backend
    try {
      final response = await apiClient.dio.get(Endpoints.me);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        await tokenManager.saveTokens(
          accessToken: token,
          refreshToken: (await tokenManager.getRefreshToken()) ?? '',
          userData: jsonEncode(user.toJson()),
        );
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        await tokenManager.clearTokens();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // If we had cached user and it was just a transient connection issue, keep authenticated
      if (cachedUser == null) {
        await tokenManager.clearTokens();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: () => null);

    try {
      final response = await apiClient.dio.post(
        Endpoints.login,
        data: {'username': username.trim(), 'password': password},
      );

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);

      await tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: jsonEncode(user.toJson()),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: () => null,
      );
      return true;
    } catch (e) {
      final msg = ApiClient.parseError(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: () => msg,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await tokenManager.getRefreshToken();
      if (refreshToken != null) {
        await apiClient.dio.post(Endpoints.logout, data: {'refresh_token': refreshToken});
      }
    } catch (_) {}

    await tokenManager.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleSessionExpired() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Your session has expired. Please sign in again.',
    );
  }
}
