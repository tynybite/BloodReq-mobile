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

  // We keep these for non-firebase scenarios or fallback, but primary source is FirebaseAuth
  String? _accessToken;

  /// Initialize with stored tokens
  Future<void> init() async {
    _accessToken = await _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Helper to get the most up-to-date valid token
  Future<String?> _getValidToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // getIdToken(false) returns the cached token if valid, or refreshes it if expired.
        // This handles the lifecycle automatically.
        final token = await user.getIdToken();
        if (token != null) {
          // Update local cache just in case
          _accessToken = token;
          return token;
        }
      }
    } catch (e) {
      debugPrint('Error fetching fresh token: $e');
    }
    return _accessToken;
  }

  /// Get authorization headers with a specific token
  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Save tokens after login/signup
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;

    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    _accessToken = null;

    await _storage.deleteAll();
  }

  /// Check if user has valid token (basic check)
  bool get hasToken => _accessToken != null;

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

      // Proactively get valid token
      final token = await _getValidToken();
      final headers = _getHeaders(token);

      var response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      // Handle 401 - if proactive fetch failed or token was revoked
      if (response.statusCode == 401) {
        debugPrint('401 in GET despite proactive fetch. Forcing refresh...');
        // Force refresh
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true);
            if (newToken != null) {
              response = await http
                  .get(uri, headers: _getHeaders(newToken))
                  .timeout(ApiConfig.timeout);
            }
          }
        } catch (e) {
          debugPrint('Force refresh failed: $e');
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

      final token = await _getValidToken();
      final headers = _getHeaders(token);

      var response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        debugPrint('401 in POST. Forcing refresh...');
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true);
            if (newToken != null) {
              response = await http
                  .post(
                    uri,
                    headers: _getHeaders(newToken),
                    body: body != null ? jsonEncode(body) : null,
                  )
                  .timeout(ApiConfig.timeout);
            }
          }
        } catch (e) {
          debugPrint('Force refresh failed: $e');
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

  /// Make a PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final token = await _getValidToken();
      final headers = _getHeaders(token);

      var response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true);
            if (newToken != null) {
              response = await http
                  .put(
                    uri,
                    headers: _getHeaders(newToken),
                    body: body != null ? jsonEncode(body) : null,
                  )
                  .timeout(ApiConfig.timeout);
            }
          }
        } catch (e) {
          /* ignore */
        }
      }

      final json = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(json, response.statusCode);
    } on TimeoutException {
      return ApiResponse.error('Request timed out', statusCode: 408);
    } catch (e) {
      debugPrint('PUT $endpoint error: $e');
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

      final token = await _getValidToken();
      final headers = _getHeaders(token);

      var response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true);
            if (newToken != null) {
              response = await http
                  .patch(
                    uri,
                    headers: _getHeaders(newToken),
                    body: body != null ? jsonEncode(body) : null,
                  )
                  .timeout(ApiConfig.timeout);
            }
          }
        } catch (e) {
          /* ignore */
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

      final token = await _getValidToken();
      final headers = _getHeaders(token);

      var response = await http
          .delete(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final newToken = await user.getIdToken(true);
            if (newToken != null) {
              response = await http
                  .delete(uri, headers: _getHeaders(newToken))
                  .timeout(ApiConfig.timeout);
            }
          }
        } catch (e) {
          /* ignore */
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
