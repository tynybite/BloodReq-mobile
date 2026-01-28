import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/scroll_control_provider.dart';
import '../../../core/services/sync_service.dart';
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

  // Filters
  String? _selectedBloodGroup;
  String _selectedUrgency = 'all';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _refreshFromCache();
  }

  void _refreshFromCache() {
    final syncService = context.read<SyncService>();
    final allRequests = syncService.getCachedRequests();

    if (mounted) {
      setState(() {
        _requests = allRequests;
        _isLoading = false;
        _splitLists();
      });
    }
  }

  void _splitLists() {
    if (_requests.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final userBloodGroup = authProvider.user?.bloodGroup;

    // Apply filters
    var filteredRequests = _requests.where((r) {
      if (_selectedBloodGroup != null && r.bloodGroup != _selectedBloodGroup) {
        return false;
      }
      if (_selectedUrgency != 'all' && r.urgency != _selectedUrgency) {
        return false;
      }
      return true;
    }).toList();

    if (userBloodGroup != null) {
      _matchingRequests = filteredRequests
          .where((r) => r.bloodGroup == userBloodGroup)
          .toList();
      _otherRequests = filteredRequests
          .where((r) => r.bloodGroup != userBloodGroup)
          .toList();
    } else {
      _matchingRequests = [];
      _otherRequests = filteredRequests;
    }
  }

  // Location request removed - not used in current implementation

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncData();
          _refreshFromCache();
        },
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
              _buildAppBar(isDark),
              _buildFilterChips(isDark),
              _buildContent(isDark),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      backgroundColor: context.scaffoldBg,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Blood Requests',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                context.scaffoldBg,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Blood Group Filter
            _QuickFilterChip(
              label: _selectedBloodGroup ?? 'Blood Type',
              icon: Icons.water_drop_outlined,
              isActive: _selectedBloodGroup != null,
              onTap: _showBloodGroupFilter,
            ),
            const SizedBox(width: 10),
            // Urgency Filters
            _QuickFilterChip(
              label: 'Critical',
              icon: Icons.priority_high,
              isActive: _selectedUrgency == 'critical',
              activeColor: AppColors.urgencyCritical,
              onTap: () => _setUrgencyFilter('critical'),
            ),
            const SizedBox(width: 10),
            _QuickFilterChip(
              label: 'Urgent',
              icon: Icons.schedule,
              isActive: _selectedUrgency == 'urgent',
              activeColor: AppColors.urgencyUrgent,
              onTap: () => _setUrgencyFilter('urgent'),
            ),
            const SizedBox(width: 10),
            if (_selectedBloodGroup != null || _selectedUrgency != 'all')
              _QuickFilterChip(
                label: 'Clear',
                icon: Icons.close,
                isActive: false,
                onTap: _clearFilters,
              ),
          ],
        ),
      ),
    );
  }

  void _setUrgencyFilter(String urgency) {
    setState(() {
      _selectedUrgency = _selectedUrgency == urgency ? 'all' : urgency;
      _splitLists();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedBloodGroup = null;
      _selectedUrgency = 'all';
      _splitLists();
    });
  }

  void _showBloodGroupFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Blood Type',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: AppConstants.bloodGroups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _BloodTypeOption(
                    label: 'All',
                    isSelected: _selectedBloodGroup == null,
                    onTap: () {
                      setState(() {
                        _selectedBloodGroup = null;
                        _splitLists();
                      });
                      Navigator.pop(context);
                    },
                  );
                }
                final group = AppConstants.bloodGroups[index - 1];
                return _BloodTypeOption(
                  label: group,
                  isSelected: _selectedBloodGroup == group,
                  onTap: () {
                    setState(() {
                      _selectedBloodGroup = group;
                      _splitLists();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
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

    final allFiltered = [..._matchingRequests, ..._otherRequests];

    if (allFiltered.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Matching Requests Section
          if (_matchingRequests.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.favorite,
              title: 'Your Blood Type Match',
              subtitle: '${_matchingRequests.length} requests need your help',
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: 12),
            ..._matchingRequests.asMap().entries.map((entry) {
              return _ModernRequestCard(
                    request: entry.value,
                    isHighlighted: true,
                    onTap: () => context.push('/request/${entry.value.id}'),
                  )
                  .animate(delay: Duration(milliseconds: entry.key * 60))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            }),
            const SizedBox(height: 24),
          ],

          // Other Requests Section
          if (_otherRequests.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.people_outline,
              title: 'Other Requests',
              subtitle: '${_otherRequests.length} people need blood',
              iconColor: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            ..._otherRequests.asMap().entries.map((entry) {
              return _ModernRequestCard(
                    request: entry.value,
                    isHighlighted: false,
                    onTap: () => context.push('/request/${entry.value.id}'),
                  )
                  .animate(delay: Duration(milliseconds: entry.key * 40))
                  .fadeIn(duration: 250.ms);
            }),
          ],
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.water_drop_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No blood requests found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedBloodGroup != null || _selectedUrgency != 'all'
                  ? 'Try adjusting your filters'
                  : 'Check back later for new requests',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedBloodGroup != null || _selectedUrgency != 'all')
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                context.read<SyncService>().syncData().then(
                  (_) => _refreshFromCache(),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN REQUEST CARD
// ─────────────────────────────────────────────────────────────

class _ModernRequestCard extends StatelessWidget {
  final BloodRequest request;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ModernRequestCard({
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Blood Group Badge
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isHighlighted
                            ? [AppColors.primary, AppColors.primaryLight]
                            : [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.primary.withValues(alpha: 0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        request.bloodGroup,
                        style: TextStyle(
                          color: isHighlighted
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: urgencyColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                request.urgency.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: urgencyColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                request.hospital,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
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

            // Footer with date and units
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Needed by ${DateFormat('MMM d').format(request.requiredDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${request.units} unit${request.units > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BloodTypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BloodTypeOption({
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
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
