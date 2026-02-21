import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../features/fundraisers/screens/bkash_webview_screen.dart';

class BkashService {
  static final BkashService _instance = BkashService._internal();
  factory BkashService() => _instance;
  BkashService._internal();

  final ApiService _api = ApiService();

  /// Initiate a bKash donation for a fundraiser.
  ///
  /// [amountBdt] — integer BDT value (e.g. 500 = ৳500)
  ///
  /// Returns `true` on success, `false` on cancellation, throws on error.
  Future<bool> donateTo({
    required String fundraiserId,
    required int amountBdt,
    required BuildContext context,
  }) async {
    // Step 1: Ask backend to create a bKash payment → get checkout URL
    final response = await _api.post(
      '/payments/bkash/create',
      body: {'fundraiser_id': fundraiserId, 'amount_bdt': amountBdt},
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to create bKash payment');
    }

    final data = response.data as Map<String, dynamic>;
    final bkashUrl = data['bkash_url'] as String?;

    if (bkashUrl == null || bkashUrl.isEmpty) {
      throw Exception('No bKash checkout URL returned');
    }

    // Step 2: Open bKash checkout in WebView
    // Returns true = success deep link received, false = cancelled/failed
    if (!context.mounted) return false;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BkashWebViewScreen(
          checkoutUrl: bkashUrl,
          fundraiserId: fundraiserId,
        ),
      ),
    );

    return result == true;
  }
}
