import 'dart:async';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'cache_service.dart';
import '../models/blood_request.dart';
import '../constants/app_constants.dart';

class SyncService extends ChangeNotifier {
  final ApiService _api = ApiService();
  final CacheService _cache = CacheService();
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Initialize Cache and Background Sync
  Future<void> init() async {
    await _cache.init();

    // Initial fetch if online
    syncData();

    // Schedule 30 min sync
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      syncData();
    });
  }

  List<BloodRequest> getCachedRequests() {
    return _cache.getRequests();
  }

  /// Manually trigger sync
  Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Sync Pending Verifications (Offline -> Online)
      await _syncPendingVerifications();

      // 2. Fetch Latest Requests (Online -> Offline)
      // Only fetch approved requests for public list
      final response = await _api.get<dynamic>(
        '${ApiEndpoints.bloodRequests}?status=approved',
      );

      if (response.success && response.data != null) {
        List<dynamic> rawList = [];

        if (response.data is List) {
          rawList = response.data;
        } else if (response.data is Map) {
          final mapData = response.data as Map<String, dynamic>;
          rawList = mapData['data'] ?? mapData['requests'] ?? [];
        }

        final List<BloodRequest> requests = rawList
            .map((json) => BloodRequest.fromJson(json))
            .toList();

        await _cache.saveRequests(requests);
        debugPrint(
          '✅ SyncService: Updated cache with ${requests.length} requests',
        );
      }
    } catch (e) {
      debugPrint('🔻 SyncService: Failed to sync ($e)');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Process offline verifications
  Future<void> _syncPendingVerifications() async {
    final pending = _cache.getPendingVerifications();
    if (pending.isEmpty) return;

    debugPrint(
      '🔄 SyncService: Processing ${pending.length} pending verifications...',
    );

    for (final verification in pending) {
      try {
        final response = await _api.post(
          '/donations/verify', // Use constant if available, else literal for now
          body: {
            'request_id': verification.requestId,
            'donor_id': verification.donorId,
            'verification_code': verification.verificationCode,
            'timestamp': verification.timestamp.toIso8601String(),
          },
        );

        if (response.success) {
          debugPrint(
            '✅ SyncService: Verification synced for ${verification.requestId}',
          );
          await _cache.removePendingVerification(verification);
        } else {
          debugPrint(
            '⚠️ SyncService: Verification sync failed: ${response.message}',
          );
          // Keep in cache to retry later?
          // If 400 (invalid code), maybe remove? For now, keep it to be safe.
        }
      } catch (e) {
        debugPrint('❌ SyncService: Error syncing verification: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
