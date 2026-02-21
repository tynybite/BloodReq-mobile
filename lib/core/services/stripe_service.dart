import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../services/api_service.dart';
import '../constants/app_theme.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final ApiService _api = ApiService();
  bool _initialized = false;

  /// Call once after fetching the publishable key from backend
  Future<void> _ensureInitialized(String publishableKey) async {
    if (_initialized && Stripe.publishableKey == publishableKey) return;
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  /// Full Stripe payment flow for donating to a fundraiser.
  ///
  /// [amount] — USD dollar amount (e.g. 5.0 = $5.00).
  /// Returns `true` on success, `false` on cancellation, throws on error.
  Future<bool> donateTo({
    required String fundraiserId,
    required double amount, // USD dollars, e.g. 5.0 = $5.00
    required BuildContext context,
  }) async {
    // Capture theme synchronously BEFORE any awaits
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Step 1: Create PaymentIntent on backend ───────────────────────────────
    final intentResponse = await _api.post(
      '/fundraisers/$fundraiserId/donate',
      body: {'amount': amount},
    );

    if (!intentResponse.success || intentResponse.data == null) {
      throw Exception(
        intentResponse.message ?? 'Failed to create payment intent',
      );
    }

    final data = intentResponse.data as Map<String, dynamic>;
    final clientSecret = data['client_secret'] as String?;
    final publishableKey = data['publishable_key'] as String?;
    final paymentIntentId = data['payment_intent_id'] as String?;

    if (clientSecret == null ||
        publishableKey == null ||
        paymentIntentId == null) {
      throw Exception('Invalid response from server');
    }

    // ── Step 2: Initialize Stripe & show payment sheet ────────────────────────
    await _ensureInitialized(publishableKey);

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'BloodReq',
        style: isDark ? ThemeMode.dark : ThemeMode.light,
        appearance: PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(primary: AppColors.primary),
        ),
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false; // User dismissed — not an error
      }
      rethrow;
    }

    // ── Step 3: Confirm with backend (server-side verification) ───────────────
    final confirmResponse = await _api.post(
      '/fundraisers/$fundraiserId/donate',
      body: {'payment_intent_id': paymentIntentId},
    );

    if (!confirmResponse.success) {
      throw Exception(
        confirmResponse.message ??
            'Payment succeeded but could not record donation',
      );
    }

    return true;
  }
}
