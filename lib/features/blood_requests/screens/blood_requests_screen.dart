import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/models/blood_request.dart';

class BloodRequestsScreen extends StatefulWidget {
  const BloodRequestsScreen({super.key});

  @override
  State<BloodRequestsScreen> createState() => _BloodRequestsScreenState();
}

class _BloodRequestsScreenState extends State<BloodRequestsScreen> {
  // Mode: Single List
  List<BloodRequest> _requests = [];

  // Mode: Split List (Location + Defaults)
  List<BloodRequest> _matchingRequests = [];
  List<BloodRequest> _otherRequests = [];
  Position? _currentPosition;

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
    // 1. Load instantly from cache
    _refreshFromCache();

    // 2. Trigger sync if needed (SyncService handles 30min interval, but we can force one on screen open if we want)
    // context.read<SyncService>().syncData();

    // 3. Get location for sorting
    await _getCurrentLocation();
  }

  void _refreshFromCache() {
    final syncService = context.read<SyncService>();
    final allRequests = syncService.getCachedRequests();

    if (mounted) {
      setState(() {
        _requests = allRequests;
        _isLoading = false;
        // Logic to split lists will be here or in build
        _splitLists();
      });
    }
  }

  void _splitLists() {
    if (_requests.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final userBloodGroup = authProvider.user?.bloodGroup;

    if (_currentPosition != null && userBloodGroup != null) {
      // Logic for splitting would go here (same as before but with Objects)
      // For now, simpler implementation:
      _matchingRequests = _requests
          .where((r) => r.bloodGroup == userBloodGroup)
          .toList();
      _otherRequests = _requests
          .where((r) => r.bloodGroup != userBloodGroup)
          .toList();
    } else {
      _matchingRequests = [];
      _otherRequests = [];
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      // Continue without location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Blood Requests'),
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncData();
          _refreshFromCache();
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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

    // Split List Mode
    if (_matchingRequests.isNotEmpty || _otherRequests.isNotEmpty) {
      return _buildSplitList();
    }

    // Standard Mode Empty State
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No blood requests found',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to request blood',
              style: TextStyle(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-request'),
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
            ),
          ],
        ),
      );
    }

    // Standard Mode List
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _RequestCard(
              request: request,
              onTap: () => context.push('/request/${request.id}'),
            )
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildSplitList() {
    return CustomScrollView(
      slivers: [
        if (_matchingRequests.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended for You',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final request = _matchingRequests[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RequestCard(
                  request: request,
                  onTap: () => context.push('/request/${request.id}'),
                ).animate().fadeIn().slideX(),
              );
            }, childCount: _matchingRequests.length),
          ),
        ],
        if (_otherRequests.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Other Nearby Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final request = _otherRequests[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RequestCard(
                  request: request,
                  onTap: () => context.push('/request/${request.id}'),
                ).animate().fadeIn(),
              );
            }, childCount: _otherRequests.length),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedBloodGroup = null;
                          _selectedUrgency = 'all';
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Blood Group Filter
                Text(
                  'Blood Group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedBloodGroup == null,
                      onTap: () =>
                          setSheetState(() => _selectedBloodGroup = null),
                    ),
                    ...AppConstants.bloodGroups.map(
                      (group) => _FilterChip(
                        label: group,
                        isSelected: _selectedBloodGroup == group,
                        onTap: () =>
                            setSheetState(() => _selectedBloodGroup = group),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Urgency Filter
                Text(
                  'Urgency',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedUrgency == 'all',
                      onTap: () =>
                          setSheetState(() => _selectedUrgency = 'all'),
                    ),
                    _FilterChip(
                      label: 'Critical',
                      isSelected: _selectedUrgency == 'critical',
                      onTap: () =>
                          setSheetState(() => _selectedUrgency = 'critical'),
                      color: AppColors.urgencyCritical,
                    ),
                    _FilterChip(
                      label: 'Urgent',
                      isSelected: _selectedUrgency == 'urgent',
                      onTap: () =>
                          setSheetState(() => _selectedUrgency = 'urgent'),
                      color: AppColors.urgencyUrgent,
                    ),
                    _FilterChip(
                      label: 'Planned',
                      isSelected: _selectedUrgency == 'planned',
                      onTap: () =>
                          setSheetState(() => _selectedUrgency = 'planned'),
                      color: AppColors.urgencyPlanned,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      context.read<SyncService>().syncData().then(
                        (_) => _refreshFromCache(),
                      );
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BloodRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Blood Group Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  request.bloodGroup,
                  style: TextStyle(
                    color: AppColors.primary,
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
                  Text(
                    request.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                        request
                            .location, // Assuming city is part of location or not available in new model yet
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

            // Urgency & Units
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.urgency.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: urgencyColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${request.units} unit${request.units > 1 ? 's' : ''}',
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : AppColors.border),
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
