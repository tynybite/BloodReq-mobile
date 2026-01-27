import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/utils/avatar_utils.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _leaders = [];
  bool _isLoading = true;
  String? _error;
  String _period = 'all_time'; // all_time, monthly, weekly

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>(
      '/leaderboard',
      queryParams: {'period': _period},
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      List<dynamic> leadersList;

      if (response.data is List) {
        leadersList = response.data as List;
      } else if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        leadersList =
            (mapData['data'] ??
                    mapData['leaders'] ??
                    mapData['leaderboard'] ??
                    [])
                as List;
      } else {
        leadersList = [];
      }

      setState(() {
        _leaders = leadersList.map((e) => e as Map<String, dynamic>).toList();
      });
    } else {
      setState(() => _error = response.message ?? 'Failed to load leaderboard');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Top Blood Donors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Heroes saving lives',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Period Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'All Time',
                    isSelected: _period == 'all_time',
                    onTap: () {
                      setState(() => _period = 'all_time');
                      _loadLeaderboard();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'This Month',
                    isSelected: _period == 'monthly',
                    onTap: () {
                      setState(() => _period = 'monthly');
                      _loadLeaderboard();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'This Week',
                    isSelected: _period == 'weekly',
                    onTap: () {
                      setState(() => _period = 'weekly');
                      _loadLeaderboard();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLeaderboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_leaders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 80,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No donors yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to donate blood!',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final leader = _leaders[index];
                  return _LeaderCard(
                        rank: index + 1,
                        name:
                            leader['full_name'] ??
                            leader['name'] ??
                            'Anonymous',
                        donations:
                            leader['total_donations'] ??
                            leader['donations'] ??
                            0,
                        points: leader['points'] ?? 0,
                        avatarUrl: leader['avatar_url'],
                        bloodGroup: leader['blood_group'],
                      )
                      .animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1, end: 0);
                }, childCount: _leaders.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final int rank;
  final String name;
  final int donations;
  final int points;
  final String? avatarUrl;
  final String? bloodGroup;

  const _LeaderCard({
    required this.rank,
    required this.name,
    required this.donations,
    required this.points,
    this.avatarUrl,
    this.bloodGroup,
  });

  Color get rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textTertiary;
    }
  }

  IconData get rankIcon {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 2)
            : null,
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
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? rankColor.withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 20)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: AvatarUtils.getImageProvider(avatarUrl),
            child: !AvatarUtils.hasAvatar(avatarUrl)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (bloodGroup != null) ...[
                      Text(
                        bloodGroup!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(' • '),
                    ],
                    Text(
                      '$donations donations',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'points',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
