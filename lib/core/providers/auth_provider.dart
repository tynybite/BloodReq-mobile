import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;
  String? _accessToken;
  String? _refreshToken;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _checkAuthStatus();
  }

  /// HTTP headers with auth token
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<void> _checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _accessToken = await _secureStorage.read(
        key: AppConstants.accessTokenKey,
      );
      _refreshToken = await _secureStorage.read(
        key: AppConstants.refreshTokenKey,
      );

      if (_accessToken != null) {
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.profile}'),
            headers: _authHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _user = UserModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Don't throw - just continue without profile
    }
  }

  /// Save tokens securely
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: accessToken,
    );
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.signIn}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveTokens(
          data['data']['access_token'],
          data['data']['refresh_token'],
        );

        if (data['data']['user'] != null) {
          _user = UserModel.fromJson(data['data']['user']);
        } else {
          await _loadUserProfile();
        }

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Sign in failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String bloodGroup,
    required String country,
    required String city,
    String? area,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.signUp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'blood_group': bloodGroup,
          'country': country,
          'city': city,
          'area': area,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // If session is returned, save tokens
        if (data['data']['access_token'] != null) {
          await _saveTokens(
            data['data']['access_token'],
            data['data']['refresh_token'],
          );
          await _loadUserProfile();
          _status = AuthStatus.authenticated;
        } else {
          // Email verification required
          _status = AuthStatus.unauthenticated;
        }

        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Sign up failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Request phone OTP
  Future<bool> requestPhoneOtp(String phoneNumber) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.signInPhone}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      final data = jsonDecode(response.body);
      _status = AuthStatus.unauthenticated;
      notifyListeners();

      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Verify phone OTP
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.verifyOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
          'type': 'signin',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveTokens(
          data['data']['access_token'],
          data['data']['refresh_token'],
        );
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'OTP verification failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Password reset request
  Future<bool> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.forgotPassword}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.signOut}'),
        headers: _authHeaders,
      );
    } catch (_) {}

    await _secureStorage.deleteAll();
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.refresh}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveTokens(
          data['data']['access_token'],
          data['data']['refresh_token'],
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.profile}'),
        headers: _authHeaders,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        await _loadUserProfile();
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Toggle donation availability
  Future<bool> toggleDonationAvailability() async {
    if (_user == null) return false;

    return await updateProfile({
      'is_available_to_donate': !_user!.isAvailableToDonate,
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
