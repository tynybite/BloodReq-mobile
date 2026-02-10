import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../shared/utils/avatar_utils.dart';
import '../../../shared/widgets/donor_avatar_ring.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/scroll_control_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/blood_request.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/request_card.dart';
import '../../../shared/widgets/fundraiser_card.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/native_ad_widget.dart';
import '../widgets/hero_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _unifiedFeed = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  int _calculateTotalItemCount() {
    if (_unifiedFeed.isEmpty) return 0;
    final adCount = (_unifiedFeed.length / 3).floor();
    return _unifiedFeed.length + adCount;
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Blood Requests (from SyncService)
      final syncService = context.read<SyncService>();
      final requests = syncService.getCachedRequests();

      // 2. Fetch Fundraisers (Direct API)
      final api = ApiService();
      final fundResponse = await api.get<dynamic>('/fundraisers');
      List<Map<String, dynamic>> fundraisers = [];

      if (fundResponse.success && fundResponse.data != null) {
        if (fundResponse.data is List) {
          fundraisers = (fundResponse.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else if (fundResponse.data is Map) {
          final mapData = fundResponse.data as Map<String, dynamic>;
          final list =
              (mapData['data'] ?? mapData['fundraisers'] ?? []) as List;
          fundraisers = list.map((e) => e as Map<String, dynamic>).toList();
        }
      }

      // 3. Combine and Sort
      final combined = [...requests, ...fundraisers];

      combined.sort((a, b) {
        DateTime dateA;
        DateTime dateB;

        if (a is BloodRequest) {
          dateA = a.createdAt;
        } else {
          final map = a as Map<String, dynamic>;
          dateA = DateTime.parse(
            map['created_at'] ?? DateTime.now().toIso8601String(),
          );
        }

        if (b is BloodRequest) {
          dateB = b.createdAt;
        } else {
          final map = b as Map<String, dynamic>;
          dateB = DateTime.parse(
            map['created_at'] ?? DateTime.now().toIso8601String(),
          );
        }

        return dateB.compareTo(dateA); // Descending
      });

      // 4. Take top 10
      if (mounted) {
        setState(() {
          _unifiedFeed = combined.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home feed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userName = (user != null && user.fullName.isNotEmpty)
        ? user.fullName
        : 'Savior';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final scrollProvider = Provider.of<ScrollControlProvider>(
              context,
              listen: false,
            );
            if (notification.direction == ScrollDirection.reverse) {
              scrollProvider.hideBottomNav();
            } else if (notification.direction == ScrollDirection.forward) {
              scrollProvider.showBottomNav();
            }
            return true;
          },
          child: CustomScrollView(
            slivers: [
              // Top App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: context.scaffoldBg,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 72,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // User Avatar
                        GestureDetector(
                          onTap: () => context.push('/edit-profile'),
                          child: DonorAvatarRing(
                            isDonor: user?.isAvailableToDonate ?? false,
                            padding: 2.0,
                            borderWidth: 2.0,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                shape: BoxShape.circle,
                                image: AvatarUtils.hasAvatar(user?.avatarUrl)
                                    ? DecorationImage(
                                        image: AvatarUtils.getImageProvider(
                                          user!.avatarUrl,
                                        )!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !AvatarUtils.hasAvatar(user?.avatarUrl)
                                  ? Center(
                                      child: Text(
                                        (user?.initials.isNotEmpty ?? false)
                                            ? user!.initials
                                            : 'S',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Welcome Text
                        Expanded(
                          child: Consumer<LanguageProvider>(
                            builder: (context, lang, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.getText('welcome'),
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userName == 'Savior'
                                        ? lang.getText('savior')
                                        : userName,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Notification Button
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                color: context.textSecondary,
                                iconSize: 22,
                                onPressed: () => context.push('/notifications'),
                              ),
                            ),
                            // Unread Badge
                            FutureBuilder<ApiResponse<dynamic>>(
                              future: ApiService().get('/notifications'),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.success ||
                                    snapshot.data!.data == null) {
                                  return const SizedBox.shrink();
                                }

                                final data = snapshot.data!.data;
                                if (data is! Map<String, dynamic> ||
                                    !data.containsKey('unread_count')) {
                                  return const SizedBox.shrink();
                                }

                                final count = data['unread_count'] as int? ?? 0;
                                if (count <= 0) return const SizedBox.shrink();

                                return Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      count > 9 ? '9+' : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sponsored Campaigns Carousel
              SliverToBoxAdapter(
                child:
                    Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 0),
                          child: HeroCarousel(city: user?.city, limit: 5),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),
              ),

              // Banner Ad - After Hero Carousel
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ), // Removed vertical padding
                  child: BannerAdWidget(height: 50),
                ),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    4,
                  ), // Reduced top/bottom padding significantly
                  child: Consumer<LanguageProvider>(
                    builder: (context, lang, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.water_drop,
                              iconColor: AppColors.primary,
                              value: user?.totalDonations.toString() ?? '0',
                              label: lang.getText('donations'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star,
                              iconColor: AppColors.accent,
                              value: user?.points.toString() ?? '0',
                              label: lang.getText('points'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.emoji_events,
                              iconColor: AppColors.success,
                              value:
                                  user?.calculatedBadgeTier.toUpperCase() ??
                                  lang.getText('new_badge'),
                              label: lang.getText('badge'),
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<LanguageProvider>(
                    builder: (context, lang, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.getText('quick_actions'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          Row(
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.search,
                                  title: lang.getText('find_requests'),
                                  color: AppColors.info,
                                  onTap: () => context.go('/requests'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.leaderboard,
                                  title: lang.getText('leaderboard'),
                                  color: AppColors.accent,
                                  onTap: () => context.push('/leaderboard'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
                ),
              ),

              // Recent Updates Section (Unified Feed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    8,
                  ), // Added small top padding back
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<LanguageProvider>(
                        builder: (context, lang, _) {
                          return Text(
                            lang.getText('recent_updates'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      // Optional: Link to see all requests if mostly requests, or remove
                    ],
                  ),
                ),
              ),

              // Unified Feed List
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_unifiedFeed.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Consumer<LanguageProvider>(
                        builder: (context, lang, _) {
                          return Text(
                            lang.getText('no_recent_updates'),
                            style: TextStyle(color: AppColors.textTertiary),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      // Insert native ad after every 3 items
                      if (index > 0 && index % 4 == 0) {
                        return const NativeAdCard().animate().fadeIn().slideY(
                          begin: 0.1,
                          end: 0,
                        );
                      }

                      // Calculate actual item index (accounting for ads)
                      final itemIndex = index - (index ~/ 4);
                      if (itemIndex >= _unifiedFeed.length) {
                        return const SizedBox.shrink();
                      }

                      final item = _unifiedFeed[itemIndex];
                      if (item is BloodRequest) {
                        return RequestCard(
                          request: item,
                          onTap: () => context.push('/request/${item.id}'),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                      } else {
                        // Fundraiser Map
                        return FundraiserCard(
                          fundraiser: item,
                          onTap: () =>
                              context.push('/fundraiser/${item['id']}'),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                      }
                    }, childCount: _calculateTotalItemCount()),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
