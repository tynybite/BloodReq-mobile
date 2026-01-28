import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/blob_background.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlobBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('My Requests'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            bottom: TabBar(
              splashFactory: NoSplash.splashFactory,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Blood Requests'),
                Tab(text: 'Fundraisers'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_BloodRequestsTab(), _FundRequestsTab()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Show logical modal or separate actions?
              // For now, let's just go to create request for blood, or show modal
              // User requested merging. "or we can merge Fund request and blood request to My requests and inside that devide tabs"
              // The FAB might need to change based on tab.
              // Or just show a modal to choose which one to create.
              // For simplicity/MVP, let's keep it simple or remove FAB and put generic "Add" button that asks "Blood or Fundraiser?"
              // But since the current screen had specific logic, let's make FAB sensitive to Tab?
              // DefaultTabController doesn't easily expose index to Scaffold.
              // So we'll convert to StatefulWidget to track index.
              _showCreateOptions(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Request'),
          ),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Request',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop, color: AppColors.primary),
              ),
              title: const Text('Blood Request'),
              subtitle: const Text('Request blood for a patient'),
              onTap: () {
                context.pop();
                context.push('/create-request');
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.volunteer_activism, color: AppColors.success),
              ),
              title: const Text('Fundraiser'),
              subtitle: const Text('Start a medical fundraising campaign'),
              onTap: () {
                context.pop();
                context.push('/create-fundraiser');
                // ScaffoldMessenger.of(context).showSnackBar(
                //    const SnackBar(content: Text('Fundraiser creation coming soon!')),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodRequestsTab extends StatefulWidget {
  const _BloodRequestsTab();

  @override
  State<_BloodRequestsTab> createState() => _BloodRequestsTabState();
}

class _BloodRequestsTabState extends State<_BloodRequestsTab> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>('/blood-requests/my');

    if (mounted) {
      if (response.success && response.data != null) {
        List<dynamic> requestsList;

        if (response.data is List) {
          requestsList = response.data as List;
        } else if (response.data is Map) {
          final mapData = response.data as Map<String, dynamic>;
          requestsList = (mapData['data'] ?? mapData['requests'] ?? []) as List;
        } else {
          requestsList = [];
        }

        setState(() {
          _requests = requestsList
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      } else {
        setState(() => _error = response.message ?? 'Failed to load requests');
      }
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.info;
      case 'fulfilled':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMyRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
              'No blood requests yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a request if you need blood',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
                request: request,
                statusColor: _getStatusColor(request['status']),
                onTap: () => context.push('/request/${request['id']}'),
              )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _FundRequestsTab extends StatefulWidget {
  const _FundRequestsTab();

  @override
  State<_FundRequestsTab> createState() => _FundRequestsTabState();
}

class _FundRequestsTabState extends State<_FundRequestsTab> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _fundraisers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyFundraisers();
  }

  Future<void> _loadMyFundraisers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>('/fundraisers/my');

    if (mounted) {
      if (response.success && response.data != null) {
        List<dynamic> fundList;

        if (response.data is List) {
          fundList = response.data as List;
        } else if (response.data is Map) {
          final mapData = response.data as Map<String, dynamic>;
          fundList = (mapData['data'] ?? mapData['fundraisers'] ?? []) as List;
        } else {
          fundList = [];
        }

        setState(() {
          _fundraisers = fundList
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      } else {
        setState(
          () => _error = response.message ?? 'Failed to load fundraisers',
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMyFundraisers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fundraisers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No fundraisers yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a fundraiser to get help',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyFundraisers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fundraisers.length,
        itemBuilder: (context, index) {
          final fund = _fundraisers[index];
          return _FundraiserCard(
                fundraiser: fund,
                onTap: () => context.push('/fundraiser/${fund['id']}'),
              )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Color statusColor;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.statusColor,
    required this.onTap,
  });

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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      request['blood_group'] ?? '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['patient_name'] ?? 'Patient',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['hospital'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (request['required_date'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Needed: ${DateFormat('MMM d').format(DateTime.parse(request['required_date']))}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (request['status'] ?? 'pending').toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            // Show Verify Button if active/pending
            if (request['status'] == 'pending' ||
                request['status'] == 'approved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/verify/${request['id']}', extra: true);
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Verify Donor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FundraiserCard extends StatelessWidget {
  final Map<String, dynamic> fundraiser;
  final VoidCallback onTap;

  const _FundraiserCard({required this.fundraiser, required this.onTap});

  double get progress {
    final raised = (fundraiser['amount_raised'] ?? 0).toDouble();
    final needed = (fundraiser['amount_needed'] ?? 1).toDouble();
    return (raised / needed).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                height: 140,
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: fundraiser['cover_image_url'] != null
                    ? Image.network(
                        fundraiser['cover_image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fundraiser['title'] ?? 'Fundraiser',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fundraiser['patient_name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
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
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '৳${_formatAmount(fundraiser['amount_raised'] ?? 0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: ' raised',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '৳${_formatAmount(fundraiser['amount_needed'] ?? 0)} goal',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.volunteer_activism,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
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
}
