import 'dart:async';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Meta/FAN sample test placements from the plugin example.
  static const String _debugBannerPlacementId =
      'IMG_16_9_APP_INSTALL#2312433698835503_2964944860251047';
  static const String _debugNativePlacementId =
      'IMG_16_9_APP_INSTALL#2312433698835503_2964952163583650';
  static const String _debugInterstitialPlacementId =
      'IMG_16_9_APP_INSTALL#2312433698835503_2650502525028617';

  // Production placements should be injected with --dart-define.
  static const String _bannerPlacementId = String.fromEnvironment(
    'FAN_BANNER_PLACEMENT_ID',
    defaultValue: '',
  );
  static const String _nativePlacementId = String.fromEnvironment(
    'FAN_NATIVE_PLACEMENT_ID',
    defaultValue: '',
  );
  static const String _interstitialPlacementId = String.fromEnvironment(
    'FAN_INTERSTITIAL_PLACEMENT_ID',
    defaultValue: '',
  );
  static const String _testingDeviceId = String.fromEnvironment(
    'FAN_TESTING_DEVICE_ID',
    defaultValue: '',
  );

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode && _testingDeviceId.isNotEmpty) {
        await FacebookAudienceNetwork.init(testingId: _testingDeviceId);
      } else {
        await FacebookAudienceNetwork.init();
      }
      _isInitialized = true;
      debugPrint('Facebook Audience Network initialized successfully');
      if (kDebugMode && _testingDeviceId.isEmpty) {
        debugPrint(
          'FAN_TESTING_DEVICE_ID is not set. Read logcat for the device hash and pass it via --dart-define.',
        );
      }
    } catch (e) {
      debugPrint('Failed to initialize Facebook Audience Network: $e');
    }
  }

  String getBannerPlacementId() {
    if (kDebugMode) {
      return _debugBannerPlacementId;
    }
    return _bannerPlacementId.isNotEmpty
        ? _bannerPlacementId
        : _debugBannerPlacementId;
  }

  String getNativeBannerPlacementId() {
    if (kDebugMode) {
      return _debugNativePlacementId;
    }
    return _nativePlacementId.isNotEmpty
        ? _nativePlacementId
        : _debugNativePlacementId;
  }

  String getInterstitialPlacementId() {
    if (kDebugMode) {
      return _debugInterstitialPlacementId;
    }
    return _interstitialPlacementId.isNotEmpty
        ? _interstitialPlacementId
        : _debugInterstitialPlacementId;
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
