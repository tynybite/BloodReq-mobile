import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:bloodreq/core/services/api_service.dart';
import 'package:bloodreq/core/constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  bool _adsEnabled = false;
  bool get adsEnabled => _adsEnabled;

  // Config from API
  Map<String, dynamic>? _remoteConfig;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');

      // Fetch remote config
      await _fetchAdConfig();
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
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
          if (_adsEnabled && data['data']['config'] != null) {
            _remoteConfig = data['data']['config']['admob'];
          }
          debugPrint('Ad config fetched: adsEnabled=$_adsEnabled');
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch ad config: $e');
      // If fetch fails, we default to false (disabled) for safety in production
      // or true if you want to be aggressive, but user requested safety.
    }
  }

  String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testBannerIdAndroid : _testBannerIdiOS;
    }

    if (_remoteConfig != null && _remoteConfig!['banner_id'] != null) {
      return _remoteConfig!['banner_id'];
    }

    // In production, if config is missing, return empty or specific disabled marker
    // Warning: Returning test ID in production is a policy violation.
    debugPrint('Warning: Ad config missing in production for Banner');
    return ''; // Or handle empty string in widget to not load
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? _testInterstitialIdAndroid
          : _testInterstitialIdiOS;
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

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  Future<void> loadInterstitialAd() async {
    if (!_adsEnabled || !_isInitialized) {
      debugPrint(
        'Ads disabled or not initialized. Skipping interstitial load.',
      );
      return;
    }

    if (_isLoadingInterstitial) return;

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isLoadingInterstitial = true;

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!_adsEnabled) return;

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded');
      if (!_isLoadingInterstitial) {
        loadInterstitialAd(); // Try to load for next time
      }
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        loadInterstitialAd(); // Preload next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
