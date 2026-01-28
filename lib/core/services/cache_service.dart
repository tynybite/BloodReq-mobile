import 'package:hive_flutter/hive_flutter.dart';
import '../models/blood_request.dart';
import '../models/pending_verification.dart';

class CacheService {
  static const String _boxName = 'blood_requests_cache';
  late Box<BloodRequest> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BloodRequestAdapter());
    Hive.registerAdapter(PendingVerificationAdapter());
    _box = await Hive.openBox<BloodRequest>(_boxName);
    _verificationBox = await Hive.openBox<PendingVerification>(
      _verificationBoxName,
    );
  }

  /// Get all cached blood requests
  List<BloodRequest> getRequests() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Save API response to cache
  Future<void> saveRequests(List<BloodRequest> requests) async {
    // Clear old data and save new strictly to properly reflect deletions if any
    // or use putAll for simple key-value.
    // Here we clear to ensure cache matches latest API state exactly.
    await _box.clear();

    final Map<String, BloodRequest> entries = {
      for (var req in requests) req.id: req,
    };

    await _box.putAll(entries);
  }

  /// Clear cache
  Future<void> clear() async {
    await _box.clear();
  }

  // --- Pending Verifications (Offline) ---
  static const String _verificationBoxName = 'pending_verifications';
  late Box<PendingVerification> _verificationBox;

  Future<void> savePendingVerification(PendingVerification verification) async {
    await _verificationBox.add(verification);
  }

  List<PendingVerification> getPendingVerifications() {
    return _verificationBox.values.toList();
  }

  Future<void> removePendingVerification(
    PendingVerification verification,
  ) async {
    await verification.delete();
  }
}
