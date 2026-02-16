import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import '../../../core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? padding;
  final AdSize? adSize;

  const BannerAdWidget({
    super.key,
    this.height = 50,
    this.padding,
    this.adSize,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin {
  final AdService _adService = AdService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (!_adService.adsEnabled) return;

    if (_adService.currentProvider == AdProvider.admob) {
      _bannerAd = BannerAd(
        adUnitId: _adService.bannerAdUnitId,
        size: widget.adSize ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
            _bannerAd = null;
          },
        ),
      );
      _bannerAd!.load();
    } else if (_adService.currentProvider == AdProvider.facebook) {
      // FacebookBannerAd handles loading internally when mounted
      setState(() {
        _isAdLoaded = true; // Assume true to render the widget
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_adService.adsEnabled) {
      return const SizedBox.shrink();
    }

    // Handle Facebook Ads
    if (_adService.currentProvider == AdProvider.facebook) {
      return Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: FacebookBannerAd(
            placementId:
                _adService.bannerAdUnitId, // This returns Placement ID for FB
            bannerSize: BannerSize.STANDARD,
            listener: (result, value) {
              if (result == BannerAdResult.ERROR) {
                debugPrint("Facebook Banner Error: $value");
              }
            },
          ),
        ),
      );
    }

    // Handle AdMob Ads
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(height: widget.height); // Placeholder until loaded
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
