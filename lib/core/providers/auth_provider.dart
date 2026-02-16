import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../../shared/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final NotificationService _notificationService = NotificationService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    debugPrint('🔐 AuthProvider: Checking auth status...');

    try {
      // Add a strict timeout to the entire init process
      await Future.any([
        _initializeAuth(),
        Future.delayed(const Duration(seconds: 5), () {
          throw Exception('Auth check timed out');
        }),
      ]);
    } catch (e) {
      debugPrint('❌ AuthProvider: Auth check error/timeout: $e');
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<void> _initializeAuth() async {
    await _api.init();

    if (_api.hasToken) {
      debugPrint('🔐 AuthProvider: Token found, loading profile...');
      await _loadUserProfile();

      // If loadUserProfile fails, we might still want to consider them unauthenticated
      // or authenticated but offline. For now, let's assume if we have a token
      // but can't fetch profile, we might need to re-login or use cached data.
      // But _loadUserProfile sets _user. If _user is null, we are effectively not fully auth'd.
      if (_user != null) {
        _status = AuthStatus.authenticated;
        debugPrint('✅ AuthProvider: User authenticated as ${_user!.email}');
      } else {
        debugPrint('⚠️ AuthProvider: Token exists but profile load failed.');
        _status = AuthStatus.unauthenticated;
      }
    } else {
      debugPrint('🔐 AuthProvider: No token found.');
      _status = AuthStatus.unauthenticated;
    }
  }

  // Public retry method
  Future<void> retryAuth() => _checkAuthStatus();

  Future<void> _loadUserProfile() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      if (response.success && response.data != null) {
        _user = UserModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  UserModel? _parseUserSafely(dynamic rawUserData) {
    if (rawUserData is! Map) return null;

    final userData = Map<String, dynamic>.from(rawUserData);
    final dynamic rawId = userData['id'];
    if (rawId == null) return null;

    userData['id'] = rawId.toString();

    try {
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Error parsing user payload: $e');
      return null;
    }
  }

  Future<void> _hydrateUserFromAuthPayload(Map<String, dynamic> data) async {
    final fallbackUser =
        _parseUserSafely(data['user']) ?? _parseUserSafely(data);

    if (fallbackUser != null) {
      _user = fallbackUser;
    }

    await _loadUserProfile();
    _user ??= fallbackUser;
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // 1. Sign in with Firebase Client SDK first
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        _error = 'Firebase authentication failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // 2. Get the ID token
      final idToken = await userCredential.user!.getIdToken();

      // 3. Send ID Token to backend to get Session/Profile
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.signIn,
        body: {'idToken': idToken, 'rememberMe': true},
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        await _api.saveTokens(
          data['access_token'] ?? idToken,
          data['refresh_token'] ?? 'FIREBASE_MANAGED',
        );

        // Always hydrate from /profile so UI has complete profile fields after login.
        await _hydrateUserFromAuthPayload(data);

        _status = AuthStatus.authenticated;

        // Wire up OneSignal with user
        _setupNotifications();

        notifyListeners();
        return true;
      }

      _error = response.message ?? 'Sign in failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
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

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      default:
        return 'Authentication failed: $code';
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Initialize Google Sign In with scopes
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '861842945995-9qo9qu4aluacolr5bneb6bhm92n61uls.apps.googleusercontent.com',
      );

      // Sign out first to ensure fresh account picker
      await googleSignIn.signOut();

      // Trigger the authentication flow
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        _status = AuthStatus.unauthenticated;
        _error = 'Google sign in was cancelled';
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        _error = 'Failed to sign in to Firebase';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Get the Firebase ID token
      final firebaseIdToken = await userCredential.user!.getIdToken();

      // Send the ID token to our backend
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.oauth,
        body: {
          'provider': 'google',
          'id_token': firebaseIdToken,
          'access_token': googleAuth.accessToken,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        await _api.saveTokens(data['access_token'], data['refresh_token']);
        await _hydrateUserFromAuthPayload(data);

        _status = AuthStatus.authenticated;
        _setupNotifications();
        notifyListeners();
        return true;
      }

      _error = response.message ?? 'Google sign in failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      _error = 'Google sign in failed: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Verify Email OTP
  Future<bool> verifyEmailOtp(String email, String otp) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        body: {'email': email, 'otp': otp},
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Response contains token for direct login
        final String? customToken = data['token'];
        if (customToken != null) {
          // Sign in to Firebase with the custom token
          final userCredential = await FirebaseAuth.instance
              .signInWithCustomToken(customToken);
          if (userCredential.user != null) {
            // Now complete login with backend using standard signin flow or just save what we have?
            // The verify-otp endpoint returns a token... usually custom token.
            // We need to exchange it or getting session?
            // Actually the Mobile App needs `Session` tokens from backend (access_token / refresh_token)
            // IF the backend manages sessions.
            // But verify-otp in backend returns: { token: customToken }
            // It misses returning the Profile or Session Access Token for API calls.

            // Wait, backend verify-otp route returns:
            // { token: customToken, message: ... }

            // Mobile App uses `_api.saveTokens` which expects access_token for `_headers`.
            // If we only get Firebase Custom Token, we are logged in to Firebase but not our Backend API (via Bearer token)?
            // UNLESS the API accepts the Firebase ID Token as Bearer token?
            // `ApiService` uses `_accessToken`.

            // If we login via Firebase, we get ID Token.
            // We should save ID Token as `access_token`.
            final newIdToken = await userCredential.user!.getIdToken();
            await _api.saveTokens(newIdToken ?? '', 'FIREBASE_MANAGED');

            // Load Profile
            await _loadUserProfile();
            _status = AuthStatus.authenticated;
            _setupNotifications();

            notifyListeners();
            return true;
          }
        }
      }

      _error = response.message ?? 'Verification failed';
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

  /// Resend Email OTP
  Future<bool> resendEmailOtp(String email) async {
    try {
      final response = await _api.post(
        ApiEndpoints.resendOtp,
        body: {'email': email},
      );
      return response.success;
    } catch (e) {
      _error = e.toString();
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
    required String gender,
    String? area,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.signUp,
        body: {
          'email': email,
          'password': password,
          'city': city,
          'gender': gender,
          if (area != null) 'area': area,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Check for OTP verification requirement
        if (data['requires_verification'] == true) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return true; // Return true to indicate step 1 success (OTP sent)
        }

        // Standard flow (active immediately)
        // If session is returned, save tokens
        final accessToken =
            data['access_token'] ?? data['session']?['access_token'];
        if (accessToken != null) {
          await _api.saveTokens(
            accessToken as String,
            (data['refresh_token'] ?? data['session']?['refresh_token'] ?? '')
                as String,
          );
          await _loadUserProfile();
          _status = AuthStatus.authenticated;
        } else {
          // Fallback
          _status = AuthStatus.unauthenticated;
        }

        notifyListeners();
        return true;
      }

      _error = response.message ?? 'Sign up failed';
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
      final response = await _api.post(
        ApiEndpoints.signInPhone,
        body: {'phone_number': phoneNumber},
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();

      return response.success;
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
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        body: {'phone_number': phoneNumber, 'otp': otp, 'type': 'signin'},
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        await _api.saveTokens(data['access_token'], data['refresh_token']);
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _error = response.message ?? 'OTP verification failed';
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
      final response = await _api.post(
        ApiEndpoints.forgotPassword,
        body: {'email': email},
      );
      return response.success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _api.post(ApiEndpoints.signOut);
    } catch (_) {}

    await _api.clearTokens();

    // Remove OneSignal user
    await _notificationService.removeExternalUserId();

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Set up push notifications with user data
  void _setupNotifications() {
    if (_user == null) return;

    // Set external user ID for targeting
    _notificationService.setExternalUserId(_user!.id);

    // Set tags for targeted notifications
    // Set tags for targeted notifications
    _notificationService.setBloodGroupTag(_user!.bloodGroup);

    // Register device token with backend
    _notificationService.registerDeviceToken(_user!.id);
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      debugPrint('📤 Updating profile with keys: ${updates.keys.toList()}');
      final response = await _api.patch(ApiEndpoints.profile, body: updates);

      debugPrint(
        '📥 Profile update response: success=${response.success}, status=${response.statusCode}, message=${response.message}',
      );

      if (response.success) {
        await _loadUserProfile();
        notifyListeners();
        return true;
      }

      _error = response.message ?? 'Failed to update profile';
      return false;
    } catch (e) {
      debugPrint('❌ Profile update exception: $e');
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

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      final response = await _api.delete(ApiEndpoints.profile);

      if (response.success) {
        // Clean up
        await _api.clearTokens();
        await _notificationService.removeExternalUserId();

        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }

      _error = response.message ?? 'Failed to delete account';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
