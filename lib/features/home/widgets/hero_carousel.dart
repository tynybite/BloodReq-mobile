import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/campaigns_service.dart';
import '../../../core/constants/app_theme.dart';

/// Hero Carousel widget for displaying sponsored campaigns
/// with smooth auto-scroll animation and multi-banner support
class HeroCarousel extends StatefulWidget {
  final String? city;
  final int limit;

  const HeroCarousel({super.key, this.city, this.limit = 5});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final CampaignsService _campaignsService = CampaignsService();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  List<Campaign> _campaigns = [];
  bool _isLoading = true;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    final campaigns = await _campaignsService.getCampaigns(
      city: widget.city,
      limit: widget.limit,
    );

    if (mounted) {
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });

      // Track views for all loaded campaigns
      for (final campaign in campaigns) {
        _campaignsService.trackView(campaign.id);
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_campaigns.isEmpty || !_pageController.hasClients) return;

      final totalPages = _getTotalBanners();
      if (totalPages <= 1) return;

      final nextPage = (_currentPage + 1) % totalPages;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  int _getTotalBanners() {
    return _campaigns.fold(
      0,
      (sum, c) => sum + (c.banners.isEmpty ? 1 : c.banners.length),
    );
  }

  List<_BannerItem> _getAllBanners() {
    final items = <_BannerItem>[];
    for (final campaign in _campaigns) {
      if (campaign.banners.isEmpty) {
        // Campaign without banner - show placeholder
        items.add(_BannerItem(campaign: campaign, bannerUrl: null));
      } else {
        for (final banner in campaign.banners) {
          items.add(_BannerItem(campaign: campaign, bannerUrl: banner.url));
        }
      }
    }
    return items;
  }

  Future<void> _handleCampaignTap(Campaign campaign) async {
    // Track click
    await _campaignsService.trackClick(campaign.id);

    // Handle action based on type
    switch (campaign.action.type) {
      case 'link':
        final url = Uri.tryParse(campaign.action.value);
        if (url != null && await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        break;
      case 'phone':
        // Use sponsor's full phone (country_code + contact_phone) or fallback to action value
        final phoneNumber = campaign.sponsor.fullPhone ?? campaign.action.value;
        final tel = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(tel)) {
          await launchUrl(tel);
        }
        break;
      case 'email':
        final mail = Uri(scheme: 'mailto', path: campaign.action.value);
        if (await canLaunchUrl(mail)) {
          await launchUrl(mail);
        }
        break;
      case 'in_app':
        // Handle in-app navigation if needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (_campaigns.isEmpty) {
      return const SizedBox.shrink(); // No campaigns, hide widget
    }

    final banners = _getAllBanners();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = banners[index];
              return _CampaignCard(
                campaign: item.campaign,
                bannerUrl: item.bannerUrl,
                onTap: () => _handleCampaignTap(item.campaign),
              );
            },
          ),
        ),
        if (banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerItem {
  final Campaign campaign;
  final String? bannerUrl;

  _BannerItem({required this.campaign, required this.bannerUrl});
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final String? bannerUrl;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.bannerUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              if (bannerUrl != null)
                Image.network(
                  bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _PlaceholderBackground(campaign: campaign),
                )
              else
                _PlaceholderBackground(campaign: campaign),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sponsor badge
                    if (campaign.sponsor.name.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          campaign.sponsor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // CTA Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        campaign.action.buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Ending soon badge
                    if (campaign.isEndingSoon)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ending Soon!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBackground extends StatelessWidget {
  final Campaign campaign;

  const _PlaceholderBackground({required this.campaign});

  Color get _typeColor {
    switch (campaign.type) {
      case 'lab_offer':
        return const Color(0xFF10B981);
      case 'blood_camp':
        return const Color(0xFFEF4444);
      case 'health_checkup':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_typeColor, _typeColor.withValues(alpha: 0.7)],
        ),
      ),
    );
  }
}
