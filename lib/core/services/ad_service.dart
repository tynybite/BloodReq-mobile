import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:bloodreq/core/constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AdProvider { admob, facebook, none }

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Test Unit IDs
  final String _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  final String _testBannerIdiOS = 'ca-app-pub-3940256099942544/2934735716';
  final String _testInterstitialIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  final String _testInterstitialIdiOS =
      'ca-app-pub-3940256099942544/4411468910';
  final String _testRewardedIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  final String _testRewardedIdiOS = 'ca-app-pub-3940256099942544/1712485313';

  // Facebook Test IDs
  // IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID is the format for testing
  final String _fbTestPlacementId = "IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID";

  bool _adsEnabled = false;
  bool get adsEnabled => _adsEnabled;

  AdProvider _currentProvider = AdProvider.none;
  AdProvider get currentProvider => _currentProvider;

  // Config from API
  Map<String, dynamic>? _remoteConfig;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Fetch remote config first to determine which SDK to init
      await _fetchAdConfig();

      if (_currentProvider == AdProvider.admob) {
        await MobileAds.instance.initialize();
        debugPrint('AdService: AdMob initialized successfully');
      } else if (_currentProvider == AdProvider.facebook) {
        await FacebookAudienceNetwork.init(
          testingId:
              "37b1da9d-b48c-4103-a393-2e095e734bd6", // Optional: Add real test device ID
          iOSAdvertiserTrackingEnabled: true,
        );
        debugPrint(
          'AdService: Facebook Audience Network initialized successfully',
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('AdService: Failed to initialize: $e');
    }
  }

  Future<void> _fetchAdConfig() async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiEndpoints.adsConfig}';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _adsEnabled = data['data']['ads_enabled'] == true;

          if (_adsEnabled) {
            final config = data['data']['config'];

            // Priority: AdMob > Meta
            // We check if the provider is explicitly ENABLED in the config
            if (config != null) {
              if (config['admob'] != null &&
                  config['admob']['enabled'] == true) {
                _remoteConfig = config['admob'];
                _currentProvider = AdProvider.admob;
                debugPrint('AdService: Selected Provider: ADMOB');
              } else if (config['meta'] != null &&
                  config['meta']['enabled'] == true) {
                _remoteConfig = config['meta'];
                _currentProvider = AdProvider.facebook;
                debugPrint('AdService: Selected Provider: FACEBOOK');
              } else {
                debugPrint(
                  'AdService: No valid provider config found despite global enable.',
                );
                _adsEnabled = false;
                _currentProvider = AdProvider.none;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AdService: Failed to fetch ad config: $e');
      _adsEnabled = false;
    }
  }

  String get bannerAdUnitId {
    if (_currentProvider == AdProvider.none) return '';

    if (kDebugMode) {
      if (_currentProvider == AdProvider.admob) {
        return Platform.isAndroid ? _testBannerIdAndroid : _testBannerIdiOS;
      } else {
        return _fbTestPlacementId; // FB Test Placement
      }
    }

    if (_remoteConfig != null && _remoteConfig!['banner_id'] != null) {
      return _remoteConfig!['banner_id'];
    }

    debugPrint('Warning: Ad config missing in production for Banner');
    return '';
  }

  String get interstitialAdUnitId {
    if (_currentProvider == AdProvider.none) return '';

    if (kDebugMode) {
      if (_currentProvider == AdProvider.admob) {
        return Platform.isAndroid
            ? _testInterstitialIdAndroid
            : _testInterstitialIdiOS;
      } else {
        return _fbTestPlacementId; // FB uses same ID for testing usually, or specific interstitial ID
      }
    }

    if (_remoteConfig != null && _remoteConfig!['interstitial_id'] != null) {
      return _remoteConfig!['interstitial_id'];
    }

    debugPrint('Warning: Ad config missing in production for Interstitial');
    return '';
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testRewardedIdAndroid : _testRewardedIdiOS;
    }

    if (_remoteConfig != null && _remoteConfig!['rewarded_id'] != null) {
      return _remoteConfig!['rewarded_id'];
    }

    debugPrint('Warning: Ad config missing in production for Rewarded');
    return '';
  }

  InterstitialAd? _admobInterstitialAd;
  bool _isAdMobInterstitialLoaded = false;

  bool _isFacebookInterstitialLoaded = false;

  Future<void> loadInterstitialAd() async {
    if (!_adsEnabled || !_isInitialized) {
      debugPrint(
        'Ads disabled or not initialized. Skipping interstitial load.',
      );
      return;
    }

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    if (_currentProvider == AdProvider.admob) {
      if (_isAdMobInterstitialLoaded) return;
      await _loadAdMobInterstitial(adUnitId);
    } else if (_currentProvider == AdProvider.facebook) {
      if (_isFacebookInterstitialLoaded) return;
      await _loadFacebookInterstitial(adUnitId);
    }
  }

  Future<void> _loadAdMobInterstitial(String adUnitId) async {
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _admobInterstitialAd = ad;
          _isAdMobInterstitialLoaded = true;
          debugPrint('AdService (AdMob): Interstitial loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService (AdMob): Interstitial failed to load: $error');
          _admobInterstitialAd = null;
          _isAdMobInterstitialLoaded = false;
        },
      ),
    );
  }

  Future<void> _loadFacebookInterstitial(String placementId) async {
    await FacebookInterstitialAd.loadInterstitialAd(
      placementId: placementId,
      listener: (result, value) {
        if (result == InterstitialAdResult.LOADED) {
          _isFacebookInterstitialLoaded = true;
          debugPrint('AdService (FB): Interstitial loaded');
        } else if (result == InterstitialAdResult.ERROR) {
          _isFacebookInterstitialLoaded = false;
          debugPrint('AdService (FB): Interstitial failed to load: $value');
        } else if (result == InterstitialAdResult.DISMISSED) {
          _isFacebookInterstitialLoaded = false;
          loadInterstitialAd(); // Reload
        }
      },
    );
  }

  void showInterstitialAd() {
    if (!_adsEnabled) return;

    if (_currentProvider == AdProvider.admob) {
      if (_admobInterstitialAd != null && _isAdMobInterstitialLoaded) {
        _admobInterstitialAd!
            .fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (InterstitialAd ad) =>
              debugPrint('AdService (AdMob): ad onAdShowedFullScreenContent.'),
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
            debugPrint(
              'AdService (AdMob): $ad onAdDismissedFullScreenContent.',
            );
            ad.dispose();
            _admobInterstitialAd = null;
            _isAdMobInterstitialLoaded = false;
            loadInterstitialAd(); // Preload next one
          },
          onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
            debugPrint(
              'AdService (AdMob): $ad onAdFailedToShowFullScreenContent: $error',
            );
            ad.dispose();
            _admobInterstitialAd = null;
            _isAdMobInterstitialLoaded = false;
            loadInterstitialAd();
          },
        );
        _admobInterstitialAd!.show();
      } else {
        debugPrint(
          'AdService (AdMob): Warning: attempt to show interstitial before loaded',
        );
        loadInterstitialAd(); // Try to load for next time
      }
    } else if (_currentProvider == AdProvider.facebook) {
      if (_isFacebookInterstitialLoaded) {
        FacebookInterstitialAd.showInterstitialAd();
      } else {
        debugPrint(
          'AdService (FB): Warning: attempt to show interstitial before loaded',
        );
        loadInterstitialAd(); // Try loading if not ready
      }
    }
  }
}
