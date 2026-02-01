import 'package:flutter/material.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import '../../../core/constants/app_theme.dart';
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
  Widget? _nativeAd;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    if (_nativeAd != null) return;

    _nativeAd = FacebookNativeAd(
      placementId:
          widget.placementId ?? _adService.getNativeBannerPlacementId(),
      adType: NativeAdType.NATIVE_AD,
      width: double.infinity,
      backgroundColor: Colors.white,
      titleColor: Colors.black,
      descriptionColor: Colors.grey[700],
      buttonColor: AppColors.primary,
      buttonTitleColor: Colors.white,
      buttonBorderColor: Colors.transparent,
      keepExpandedWhileLoading: true,
      expandAnimationDuraion: 300,
      listener: (result, value) {
        switch (result) {
          case NativeAdResult.ERROR:
            debugPrint('Native ad error: $value');
            break;
          case NativeAdResult.LOADED:
            debugPrint('Native ad loaded');
            break;
          case NativeAdResult.CLICKED:
            debugPrint('Native ad clicked');
            break;
          case NativeAdResult.LOGGING_IMPRESSION:
            debugPrint('Native ad impression logged');
            break;
          case NativeAdResult.MEDIA_DOWNLOADED:
            debugPrint('Native ad media downloaded');
            break;
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
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
        child: _nativeAd,
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
