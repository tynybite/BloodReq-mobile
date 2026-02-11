import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FundraiserCacheService {
  static const String _fundraisersKey = 'cached_fundraisers';

  Future<void> saveFundraisers(List<Map<String, dynamic>> fundraisers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(fundraisers);
    await prefs.setString(_fundraisersKey, encoded);
  }

  Future<List<Map<String, dynamic>>> getFundraisers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fundraisersKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
