import 'dart:async';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Use the ID found in the file as the base for testing if available, or a placeholder
  // The user had: 2312433698835503_2964944866917713
  static const String _testPlacementId = '2312433698835503_2964944866917713';

  static const String _bannerPlacementId =
      'IMG_16_9_APP_INSTALL#$_testPlacementId';
  static const String _nativeBannerPlacementId =
      'IMG_16_9_APP_INSTALL#$_testPlacementId';
  static const String _interstitialPlacementId =
      'IMG_16_9_APP_INSTALL#$_testPlacementId';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FacebookAudienceNetwork.init(
        testingId: '58a05d9e-bea7-4382-8c2a-a757fa2ea878', // Device Hash
      );
      _isInitialized = true;
      debugPrint('Facebook Audience Network initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Facebook Audience Network: $e');
    }
  }

  String getBannerPlacementId() {
    // For testing, we use the specific test ID
    if (kDebugMode) {
      return 'IMG_16_9_APP_INSTALL#$_testPlacementId';
    }
    return _bannerPlacementId;
  }

  String getNativeBannerPlacementId() {
    if (kDebugMode) {
      return 'IMG_16_9_APP_INSTALL#$_testPlacementId';
    }
    return _nativeBannerPlacementId;
  }

  String getInterstitialPlacementId() {
    if (kDebugMode) {
      return 'IMG_16_9_APP_INSTALL#$_testPlacementId';
    }
    return _interstitialPlacementId;
  }

  Future<bool> showInterstitialAd() async {
    try {
      final isLoaded = await FacebookInterstitialAd.loadInterstitialAd(
        placementId: getInterstitialPlacementId(),
        listener: (result, value) {
          if (result == InterstitialAdResult.LOADED) {
            FacebookInterstitialAd.showInterstitialAd();
          }
        },
      );
      return isLoaded ?? false;
    } catch (e) {
      debugPrint('Failed to load interstitial ad: $e');
      return false;
    }
  }

  void destroyInterstitialAd() {
    FacebookInterstitialAd.destroyInterstitialAd();
  }
}
