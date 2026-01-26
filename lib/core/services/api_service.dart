import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Added for client-side refresh
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiResponse(
      success: json['success'] ?? (statusCode >= 200 && statusCode < 300),
      data: json['data'] as T?,
      message: json['message'] ?? json['error'],
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Centralized API Service for all HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  /// Initialize with stored tokens
  Future<void> init() async {
    _accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    _refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// Get authorization headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Save tokens after login/signup
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }

  /// Check if user has valid token
  bool get hasToken => _accessToken != null;

  /// Refresh the access token
  Future<bool> _refreshAccessToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Force refresh ID token from Firebase directly
        final newToken = await user.getIdToken(true);
        if (newToken != null) {
          debugPrint('✅ Token refreshed via Firebase SDK');
          await saveTokens(newToken, _refreshToken ?? '');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  /// Make a GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      var response = await http
          .get(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      // Handle 401 - try refresh token
      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          response = await http
              .get(uri, headers: _headers)
              .timeout(ApiConfig.timeout);
        } else {
          // If refresh fails with 401, clear tokens to force re-login
          debugPrint('Persistent 401 detected in GET. Clearing stale tokens.');
          await clearTokens();
        }
      }

      final json = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(json, response.statusCode);
    } on TimeoutException {
      return ApiResponse.error('Request timed out', statusCode: 408);
    } catch (e) {
      debugPrint('GET $endpoint error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Make a POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      var response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      // Handle 401 - try refresh token
      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          response = await http
              .post(
                uri,
                headers: _headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConfig.timeout);
        } else {
          debugPrint('Persistent 401 detected in POST. Clearing stale tokens.');
          await clearTokens();
        }
      }

      final json = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(json, response.statusCode);
    } on TimeoutException {
      return ApiResponse.error('Request timed out', statusCode: 408);
    } catch (e) {
      debugPrint('POST $endpoint error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Make a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      var response = await http
          .patch(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      // Handle 401 - try refresh token
      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          response = await http
              .patch(
                uri,
                headers: _headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConfig.timeout);
        } else {
          debugPrint(
            'Persistent 401 detected in PATCH. Clearing stale tokens.',
          );
          await clearTokens();
        }
      }

      final json = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(json, response.statusCode);
    } on TimeoutException {
      return ApiResponse.error('Request timed out', statusCode: 408);
    } catch (e) {
      debugPrint('PATCH $endpoint error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Make a DELETE request
  Future<ApiResponse<T>> delete<T>(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      var response = await http
          .delete(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      // Handle 401 - try refresh token
      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          response = await http
              .delete(uri, headers: _headers)
              .timeout(ApiConfig.timeout);
        } else {
          debugPrint(
            'Persistent 401 detected in DELETE. Clearing stale tokens.',
          );
          await clearTokens();
        }
      }

      final json = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(json, response.statusCode);
    } on TimeoutException {
      return ApiResponse.error('Request timed out', statusCode: 408);
    } catch (e) {
      debugPrint('DELETE $endpoint error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Make a raw HTTP GET request to external APIs (no auth headers)
  Future<Map<String, dynamic>?> httpGet(Uri url) async {
    try {
      final response = await http.get(url).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('HTTP GET error: $e');
      return null;
    }
  }
}
