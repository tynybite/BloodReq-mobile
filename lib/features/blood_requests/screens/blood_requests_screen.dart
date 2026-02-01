import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/scroll_control_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/blood_request.dart';

class BloodRequestsScreen extends StatefulWidget {
  const BloodRequestsScreen({super.key});

  @override
  State<BloodRequestsScreen> createState() => _BloodRequestsScreenState();
}

class _BloodRequestsScreenState extends State<BloodRequestsScreen> {
  List<BloodRequest> _requests = [];
  List<BloodRequest> _matchingRequests = [];
  List<BloodRequest> _otherRequests = [];

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Filters
  String? _selectedBloodGroup;
  String _selectedUrgency = 'all';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    _refreshFromCache();
  }

  void _refreshFromCache() {
    // Implement cache logic if needed
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      // Fetch 'active' generally, or filter by status=approved on backend
      final response = await api.get('/blood-requests');

      if (!mounted) return;

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data['requests'] ?? [];
        final allRequests = data
            .map((json) => BloodRequest.fromJson(json))
            .toList();

        // Filter valid requests (future date)
        final validRequests = allRequests.where((r) {
          final isFuture = r.requiredDate.isAfter(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          // Only show approved/urgent/critical if needed, but assuming API returns valid ones
          return isFuture;
        }).toList();

        // Sort by urgency then date
        validRequests.sort((a, b) {
          final urgencyOrder = {'critical': 0, 'urgent': 1, 'standard': 2};
          final ua = urgencyOrder[a.urgency] ?? 2;
          final ub = urgencyOrder[b.urgency] ?? 2;
          if (ua != ub) return ua.compareTo(ub);
          return a.requiredDate.compareTo(b.requiredDate);
        });

        if (mounted) {
          setState(() {
            _requests = validRequests;
            _applyFilters();
          });
        }
      } else {
        if (mounted) setState(() => _error = response.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load requests');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    // 1. Filter by Search & Selected Filters
    var filtered = _requests.where((r) {
      // Search
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          r.hospital.toLowerCase().contains(query) ||
          r.location.toLowerCase().contains(query) ||
          r.patientName.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      // Blood Group Filter
      if (_selectedBloodGroup != null && r.bloodGroup != _selectedBloodGroup) {
        return false;
      }

      // Urgency Filter
      if (_selectedUrgency != 'all' && r.urgency != _selectedUrgency) {
        return false;
      }

      return true;
    }).toList();

    // 2. Split into "Matches" (User's Blood Group) vs Others
    // TODO: Get user's actual blood group from profile
    const userBloodGroup = 'O+'; // Mock for now

    _matchingRequests = filtered
        .where((r) => r.bloodGroup == userBloodGroup)
        .toList();
    _otherRequests = filtered
        .where((r) => r.bloodGroup != userBloodGroup)
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _setUrgencyFilter(String urgency) {
    setState(() {
      _selectedUrgency = urgency;
      _applyFilters();
    });
  }

  void _showBloodGroupFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BloodTypeBottomSheet(
        selectedBloodGroup: _selectedBloodGroup,
        onSelect: (group) {
          setState(() {
            _selectedBloodGroup = group;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: AppColors.primary,
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
              _buildPremiumAppBar(isDark),
              _buildQuickStats(isDark),
              _buildFilterRow(isDark),
              _buildContent(isDark),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar(bool isDark) {
    // Count critical requests for badge
    final criticalCount = _requests
        .where((r) => r.urgency == 'critical')
        .length;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.primary,
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
                      const Color(0xFF1A1A2E),
                      const Color(0xFF2E2E4A),
                      const Color(0xFF16213E),
                    ]
                  : [
                      AppColors.primary,
                      const Color(0xFFE53935),
                      const Color(0xFFC62828),
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
                                  'Blood Requests',
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
                              'Find and help patients near you',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate(delay: 100.ms).fadeIn(),
                          ],
                        ),
                      ),
                      if (criticalCount > 0)
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
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .fade(duration: 600.ms)
                                  .scale(begin: const Offset(0.8, 0.8)),
                              const SizedBox(width: 6),
                              Text(
                                '$criticalCount Critical',
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
                  hintText: 'Search hospital, location, or name...',
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

  Widget _buildQuickStats(bool isDark) {
    final matchCount = _matchingRequests.length;
    final criticalCount = _requests
        .where((r) => r.urgency == 'critical')
        .length;
    final urgentCount = _requests.where((r) => r.urgency == 'urgent').length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
                  child: _StatCard(
                    icon: Icons.favorite_rounded,
                    label: 'Matches',
                    value: matchCount.toString(),
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(width: 12),
            Expanded(
                  child: _StatCard(
                    icon: Icons.bolt_rounded,
                    label: 'Critical',
                    value: criticalCount.toString(),
                    color: AppColors.urgencyCritical,
                    isDark: isDark,
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(width: 12),
            Expanded(
                  child: _StatCard(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Urgent',
                    value: urgentCount.toString(),
                    color: AppColors.urgencyUrgent,
                    isDark: isDark,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        margin: const EdgeInsets.only(top: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterPill(
              label: 'All Requests',
              icon: Icons.grid_view_rounded,
              isActive: _selectedUrgency == 'all',
              onTap: () => _setUrgencyFilter('all'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: 'Critical',
              icon: Icons.bolt_rounded,
              isActive: _selectedUrgency == 'critical',
              activeColor: AppColors.urgencyCritical,
              onTap: () => _setUrgencyFilter('critical'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: 'Urgent',
              icon: Icons.access_time_filled_rounded,
              isActive: _selectedUrgency == 'urgent',
              activeColor: AppColors.urgencyUrgent,
              onTap: () => _setUrgencyFilter('urgent'),
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 24,
              color: isDark
                  ? Colors.white24
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showBloodGroupFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _selectedBloodGroup != null
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedBloodGroup != null
                        ? Colors.transparent
                        : AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bloodtype_rounded,
                      size: 16,
                      color: _selectedBloodGroup != null
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedBloodGroup ?? 'Blood Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedBloodGroup != null
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                    if (_selectedBloodGroup != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(child: _buildErrorState());
    }

    if (_requests.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        if (_matchingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _SectionTitle(
              icon: Icons.wb_incandescent_rounded,
              title: "Matches for You",
              count: _matchingRequests.length,
              color: AppColors.primary,
            ),
          ),
          ..._matchingRequests.asMap().entries.map((entry) {
            final index = entry.key;
            final req = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  _PremiumRequestCard(
                        request: req,
                        isHighlighted: true,
                        onTap: () => _openRequestDetail(req),
                      )
                      .animate(delay: Duration(milliseconds: index * 100))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05, end: 0, curve: Curves.easeOut),
            );
          }),
        ],
        if (_otherRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _SectionTitle(
              icon: Icons.list_alt_rounded,
              title: "Other Requests",
              count: _otherRequests.length,
              color: AppColors.textSecondary,
            ),
          ),
          ..._otherRequests.asMap().entries.map((entry) {
            final index = entry.key;
            final req = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  _PremiumRequestCard(
                        request: req,
                        isHighlighted: false,
                        onTap: () => _openRequestDetail(req),
                      )
                      .animate(delay: Duration(milliseconds: 200 + index * 80))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05, end: 0, curve: Curves.easeOut),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bloodtype_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            'No Requests Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or adjust filters',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (_searchQuery.isNotEmpty || _selectedUrgency != 'all')
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedUrgency = 'all';
                    _selectedBloodGroup = null;
                    _searchController.clear();
                    _applyFilters();
                  });
                },
                child: const Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadRequests, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _openRequestDetail(BloodRequest request) {
    context.push('/request/${request.id}');
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
    final color = activeColor ?? AppColors.primary;

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
// SECTION TITLE
// ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM REQUEST CARD
// ─────────────────────────────────────────────────────────────

class _PremiumRequestCard extends StatelessWidget {
  final BloodRequest request;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _PremiumRequestCard({
    required this.request,
    required this.isHighlighted,
    required this.onTap,
  });

  Color get urgencyColor {
    switch (request.urgency) {
      case 'critical':
        return AppColors.urgencyCritical;
      case 'urgent':
        return AppColors.urgencyUrgent;
      default:
        return AppColors.urgencyPlanned;
    }
  }

  IconData get urgencyIcon {
    switch (request.urgency) {
      case 'critical':
        return Icons.bolt_rounded;
      case 'urgent':
        return Icons.access_time_filled_rounded;
      default:
        return Icons.event_available_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysLeft = request.requiredDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: isHighlighted ? 20 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Blood Group Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isHighlighted
                            ? [AppColors.primary, AppColors.primaryDark]
                            : [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.primary.withValues(alpha: 0.08),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        request.bloodGroup,
                        style: TextStyle(
                          color: isHighlighted
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.patientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: context.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: urgencyColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    urgencyIcon,
                                    size: 12,
                                    color: urgencyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.urgency.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: urgencyColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.hospital,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
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

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: daysLeft <= 1
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    daysLeft <= 0
                        ? 'Today'
                        : daysLeft == 1
                        ? 'Tomorrow'
                        : DateFormat('MMM d').format(request.requiredDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysLeft <= 1
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${request.units} unit${request.units > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
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

// ─────────────────────────────────────────────────────────────
// BLOOD TYPE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _BloodTypeBottomSheet extends StatelessWidget {
  final String? selectedBloodGroup;
  final Function(String?) onSelect;

  const _BloodTypeBottomSheet({
    required this.selectedBloodGroup,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Blood Type',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a blood type to filter requests',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: AppConstants.bloodGroups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _BloodTypeButton(
                        label: 'All',
                        isSelected: selectedBloodGroup == null,
                        onTap: () => onSelect(null),
                      );
                    }
                    final group = AppConstants.bloodGroups[index - 1];
                    return _BloodTypeButton(
                      label: group,
                      isSelected: selectedBloodGroup == group,
                      onTap: () => onSelect(group),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _BloodTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BloodTypeButton({
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
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
