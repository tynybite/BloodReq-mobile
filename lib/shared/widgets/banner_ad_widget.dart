import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
          // Clear reference to avoid double disposal
          // Note: references in Listener might be tricky, but this helps.
          // However, _bannerAd refers to the ad object instance.
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null; // Ensure we don't hold onto disposed ad
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(height: widget.height);
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
