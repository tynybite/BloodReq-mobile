import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pending_verification.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class VerificationService {
  final ApiService _api = ApiService();
  final CacheService _cache = CacheService();

  /// Generate a 6-digit verification code for a specific request
  /// In a real app with offline-first trust, this should be deterministic based on a shared secret
  /// OR random, and the Requestor "pushes" this valid code to the server when online.
  /// For this MVP: Requestor generates Random Code -> Shows to Donor.
  /// Donor enters it -> Verification.
  String generateCode(String requestId) {
    // Deterministic based on RequestID + Day? No, that might be guessable.
    // Random is better for security, but requires Requestor to be online to sync "I generated X"
    // OR we trust the Requestor's phone.
    // Let's use Random.
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    return code;
  }

  /// Verify a code (Donor side)
  /// Returns string message on success (e.g. "+50 Points"), throws error on failure.
  Future<Map<String, dynamic>> verifyCode({
    required String requestId,
    required String donorId,
    required String code,
  }) async {
    // 1. Try Online Verification first
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/donations/verify',
        body: {
          'request_id': requestId,
          'donor_id': donorId,
          'verification_code': code,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success) {
        return response.data ?? {'message': 'Verified!'};
      } else {
        // If 4xx error (invalid code), throw.
        // If 5xx or network error, fall through to offline.
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception(response.message ?? 'Invalid code');
        }
      }
    } catch (e) {
      if (e.toString().contains('Invalid code')) rethrow;
      // Network error? Proceed to offline save.
      debugPrint('⚠️ Network error during verification, saving offline: $e');
    }

    // 2. Offline Fallback
    // We cannot "verify" the code offline without the Requestor's secret.
    // BUT we can "Accept" it and verify later.
    final pending = PendingVerification(
      requestId: requestId,
      donorId: donorId,
      verificationCode: code,
      timestamp: DateTime.now(),
    );

    await _cache.savePendingVerification(pending);

    return {
      'offline': true,
      'message': 'Verification saved! Points will be awarded when online.',
    };
  }
}
