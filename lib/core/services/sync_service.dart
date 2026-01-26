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
      final response = await _api.get<dynamic>(ApiEndpoints.bloodRequests);

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

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
