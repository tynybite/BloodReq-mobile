import 'package:flutter/material.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import '../../../core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? padding;

  const BannerAdWidget({super.key, this.height = 50, this.padding});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin {
  final AdService _adService = AdService();
  Widget? _bannerAd;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Prevent reloading if already loaded
    if (_bannerAd != null) return;

    _bannerAd = FacebookBannerAd(
      placementId: _adService.getBannerPlacementId(),
      bannerSize: BannerSize.STANDARD,
      keepAlive: true, // Internal keep alive
      listener: (result, value) {
        switch (result) {
          case BannerAdResult.ERROR:
            debugPrint('Banner ad error: $value');
            break;
          case BannerAdResult.LOADED:
            debugPrint('Banner ad loaded');
            break;
          case BannerAdResult.CLICKED:
            debugPrint('Banner ad clicked');
            break;
          case BannerAdResult.LOGGING_IMPRESSION:
            debugPrint('Banner ad impression logged');
            break;
        }
      },
    );
    // Only set state if mounted
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _bannerAd,
      ),
    );
  }
}
