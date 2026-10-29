import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_manager.dart';
import '../config/app_config.dart';
import 'endpoints.dart';

class ApiClient {
  late final Dio dio;
  final TokenManager tokenManager;
  final String baseUrl;
  void Function()? onSessionExpired;

  ApiClient({
    required this.tokenManager,
    String? baseUrl,
    this.onSessionExpired,
  }) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl {
    dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/')) {
            // Attempt token refresh
            final refreshToken = await tokenManager.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: this.baseUrl));
                final refreshResponse = await refreshDio.post(
                  Endpoints.refresh,
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access_token'] as String;
                  final newRefreshToken = refreshResponse.data['refresh_token'] as String;
                  await tokenManager.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshErr) {
                debugPrint('Token refresh failed: $refreshErr');
                await tokenManager.clearTokens();
                onSessionExpired?.call();
              }
            } else {
              await tokenManager.clearTokens();
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static String parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check server availability.';
      }
      if (error.type == DioExceptionType.connectionError) {
        final host = error.requestOptions.baseUrl.isNotEmpty
            ? error.requestOptions.baseUrl
            : 'backend server';
        return 'Cannot connect to $host. Please check your network connection or server settings.';
      }
      return error.message ?? 'An unexpected network error occurred.';
    }
    return error.toString();
  }
}
