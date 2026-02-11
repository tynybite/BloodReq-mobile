import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/scroll_control_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/fundraiser_cache_service.dart';

class FundraisersScreen extends StatefulWidget {
  const FundraisersScreen({super.key});

  @override
  State<FundraisersScreen> createState() => _FundraisersScreenState();
}

class _FundraisersScreenState extends State<FundraisersScreen> {
  final ApiService _api = ApiService();
  final FundraiserCacheService _cache = FundraiserCacheService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _fundraisers = [];
  List<Map<String, dynamic>> _filteredFundraisers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadFundraisers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFundraisers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final response = await _api.get<dynamic>('/fundraisers');
    if (!mounted) return;

    if (response.success && response.data != null) {
      final parsedFundraisers = _parseFundraisers(response.data);
      await _cache.saveFundraisers(parsedFundraisers);
      if (!mounted) return;

      setState(() {
        _fundraisers = parsedFundraisers;
        _error = null;
        _applyFilters();
      });
    } else {
      final cachedFundraisers = await _cache.getFundraisers();
      if (!mounted) return;

      if (cachedFundraisers.isNotEmpty) {
        setState(() {
          _fundraisers = cachedFundraisers;
          _error = null;
          _applyFilters();
        });
      } else {
        setState(() => _error = lang.getText('load_fundraisers_failed'));
      }
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _parseFundraisers(dynamic data) {
    List<dynamic> fundList;

    if (data is List) {
      fundList = data;
    } else if (data is Map<String, dynamic>) {
      final rawList = data['data'] ?? data['fundraisers'];
      fundList = rawList is List ? rawList : [];
    } else {
      fundList = [];
    }

    return fundList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _applyFilters() {
    var filtered = _fundraisers.toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((f) {
        final title = (f['title'] ?? '').toString().toLowerCase();
        final patient = (f['patient_name'] ?? '').toString().toLowerCase();
        final hospital = (f['hospital'] ?? '').toString().toLowerCase();
        return title.contains(query) ||
            patient.contains(query) ||
            hospital.contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedFilter == 'urgent') {
      filtered = filtered.where((f) {
        final raised = (f['amount_raised'] ?? 0).toDouble();
        final needed = (f['amount_needed'] ?? 1).toDouble();
        final progress = raised / needed;
        return progress < 0.3;
      }).toList();
    } else if (_selectedFilter == 'almost') {
      filtered = filtered.where((f) {
        final raised = (f['amount_raised'] ?? 0).toDouble();
        final needed = (f['amount_needed'] ?? 1).toDouble();
        final progress = raised / needed;
        return progress >= 0.7 && progress < 1.0;
      }).toList();
    }

    _filteredFundraisers = filtered;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? 'all' : filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadFundraisers,
        color: AppColors.success,
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
              _buildPremiumAppBar(isDark, lang),
              _buildQuickStats(isDark, lang),
              _buildFilterRow(isDark, lang),
              _buildContent(isDark, lang),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar(bool isDark, LanguageProvider lang) {
    final totalRaised = _fundraisers.fold<double>(
      0,
      (sum, f) => sum + (f['amount_raised'] ?? 0).toDouble(),
    );

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0D2818) : AppColors.success,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D2818),
                      const Color(0xFF1A4530),
                      const Color(0xFF0F5132),
                    ]
                  : [
                      AppColors.success,
                      const Color(0xFF198754),
                      const Color(0xFF0F5132),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  lang.getText('fundraisers_title'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  end: 0,
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(height: 4),
                            Text(
                              lang
                                  .getText('active_campaigns_count')
                                  .replaceAll(
                                    '@count',
                                    '${_fundraisers.length}',
                                  ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate(delay: 100.ms).fadeIn(),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '৳${_formatAmount(totalRaised)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn().scale(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: lang.getText('search_hint'),
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, LanguageProvider lang) {
    final urgentCount = _fundraisers.where((f) {
      final raised = (f['amount_raised'] ?? 0).toDouble();
      final needed = (f['amount_needed'] ?? 1).toDouble();
      return raised / needed < 0.3;
    }).length;

    final almostThereCount = _fundraisers.where((f) {
      final raised = (f['amount_raised'] ?? 0).toDouble();
      final needed = (f['amount_needed'] ?? 1).toDouble();
      final progress = raised / needed;
      return progress >= 0.7 && progress < 1.0;
    }).length;

    return SliverToBoxAdapter(
      child:
          Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        label: lang.getText('stat_active'),
                        value: _fundraisers.length.toString(),
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.priority_high_rounded,
                        label: lang.getText('stat_urgent'),
                        value: urgentCount.toString(),
                        color: AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.stars_rounded,
                        label: lang.getText('stat_almost_there'),
                        value: almostThereCount.toString(),
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildFilterRow(bool isDark, LanguageProvider lang) {
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        margin: const EdgeInsets.only(top: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterPill(
              label: lang.getText('filter_all'),
              icon: Icons.grid_view_rounded,
              isActive: _selectedFilter == 'all',
              onTap: () => _setFilter('all'),
              isDark: isDark,
              activeColor: AppColors.success,
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: lang.getText('filter_urgent'),
              icon: Icons.warning_rounded,
              isActive: _selectedFilter == 'urgent',
              activeColor: AppColors.error,
              onTap: () => _setFilter('urgent'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: lang.getText('filter_almost_there'),
              icon: Icons.trending_up_rounded,
              isActive: _selectedFilter == 'almost',
              activeColor: AppColors.warning,
              onTap: () => _setFilter('almost'),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, LanguageProvider lang) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(child: _buildErrorState(lang));
    }

    if (_filteredFundraisers.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(lang));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final fund = _filteredFundraisers[index];
          return _PremiumFundraiserCard(
                fundraiser: fund,
                onTap: () => context.push('/fundraiser/${fund['id']}'),
              )
              .animate(delay: Duration(milliseconds: 100 + index * 80))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
        }, childCount: _filteredFundraisers.length),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.1),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                size: 56,
                color: AppColors.success,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            Text(
              lang.getText('no_fundraisers'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? lang.getText('adjust_filters_desc')
                  : lang.getText('check_back_desc'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 28),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'all';
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(lang.getText('clear_filters')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ).animate(delay: 400.ms).fadeIn().scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFundraisers,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(lang.getText('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER PILL
// ─────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isActive,
    this.activeColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : null,
          color: isActive
              ? null
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.transparent : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM FUNDRAISER CARD
// ─────────────────────────────────────────────────────────────

class _PremiumFundraiserCard extends StatelessWidget {
  final Map<String, dynamic> fundraiser;
  final VoidCallback onTap;

  const _PremiumFundraiserCard({required this.fundraiser, required this.onTap});

  double get progress {
    final raised = (fundraiser['amount_raised'] ?? 0).toDouble();
    final needed = (fundraiser['amount_needed'] ?? 1).toDouble();
    return (raised / needed).clamp(0.0, 1.0);
  }

  Color get progressColor {
    if (progress >= 0.7) return AppColors.success;
    if (progress >= 0.3) return AppColors.warning;
    return AppColors.error;
  }

  String _formatAmount(dynamic amount) {
    final num = (amount ?? 0).toDouble();
    if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(1)}L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.2),
            AppColors.success.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.volunteer_activism_rounded,
          size: 48,
          color: AppColors.success.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentText = '${(progress * 100).toInt()}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: fundraiser['cover_image_url'] != null
                        ? Image.network(
                            fundraiser['cover_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Progress badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            progress >= 0.7
                                ? Icons.trending_up_rounded
                                : Icons.trending_flat_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            percentText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      fundraiser['title'] ?? 'Fundraiser',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient & Hospital
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fundraiser['patient_name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_hospital_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fundraiser['hospital'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor,
                              progressColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '৳${_formatAmount(fundraiser['amount_raised'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: progressColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'raised',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '৳${_formatAmount(fundraiser['amount_needed'])}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
