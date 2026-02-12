import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_service.dart';

class NativeAdWidget extends StatefulWidget {
  final String? placementId;
  final EdgeInsets? margin;

  const NativeAdWidget({super.key, this.placementId, this.margin});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  final AdService _adService = AdService();
  BannerAd? _bannerAd; // Using MREC Banner as Native substitute
  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!_adService.adsEnabled) return;

    // Using default banner unit ID for now, or you could add a specific native/MREC unit ID to AdService
    // Ideally AdService should have a getNativeAdUnitId or getMrecAdUnitId
    // For this migration, we'll try to use the banner ID with MREC size,
    // or better: add `nativeAdUnitId`/`mrecAdUnitId` to AdService.
    // Let's assume we use Banner ID but ask for Medium Rectangle size.

    _bannerAd = BannerAd(
      adUnitId:
          widget.placementId ??
          _adService.bannerAdUnitId, // Reusing banner ID or use specific
      size: AdSize.mediumRectangle,
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
          debugPrint('Native (MREC) ad failed to load: $error');
          ad.dispose();
          // We don't nullify _bannerAd here inside listener easily for THIS instance
          // but we should generally handle it.
          // For now, simpler.
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 250, // MREC height
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Center(child: AdWidget(ad: _bannerAd!)),
      ),
    );
  }
}

class NativeAdCard extends StatelessWidget {
  final String? placementId;

  const NativeAdCard({super.key, this.placementId});

  @override
  Widget build(BuildContext context) {
    return NativeAdWidget(
      placementId: placementId,
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
}
