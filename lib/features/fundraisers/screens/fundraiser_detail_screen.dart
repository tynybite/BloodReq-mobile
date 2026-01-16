import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/utils/app_toast.dart';

class FundraiserDetailScreen extends StatefulWidget {
  final String fundraiserId;

  const FundraiserDetailScreen({super.key, required this.fundraiserId});

  @override
  State<FundraiserDetailScreen> createState() => _FundraiserDetailScreenState();
}

class _FundraiserDetailScreenState extends State<FundraiserDetailScreen> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _fundraiser;
  bool _isLoading = true;
  String? _error;
  bool _donating = false;

  @override
  void initState() {
    super.initState();
    _loadFundraiser();
  }

  Future<void> _loadFundraiser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>(
      '/fundraisers/${widget.fundraiserId}',
    );

    if (response.success && response.data != null) {
      if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        // Could be directly the fundraiser or wrapped in 'data'
        setState(() => _fundraiser = mapData['data'] ?? mapData);
      }
    } else {
      setState(() => _error = response.message ?? 'Failed to load fundraiser');
    }

    setState(() => _isLoading = false);
  }

  double get progress {
    final raised = (_fundraiser?['amount_raised'] ?? 0).toDouble();
    final needed = (_fundraiser?['amount_needed'] ?? 1).toDouble();
    return (raised / needed).clamp(0.0, 1.0);
  }

  Future<void> _showDonateSheet() async {
    final amountController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donate to this fundraiser',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _fundraiser?['title'] ?? 'Fundraiser',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Amount Field
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (৳)',
                    prefixIcon: const Icon(Icons.attach_money),
                    hintText: 'Enter donation amount',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Quick amounts
                Wrap(
                  spacing: 8,
                  children: [100, 500, 1000, 5000].map((amount) {
                    return ActionChip(
                      label: Text('৳$amount'),
                      onPressed: () {
                        amountController.text = amount.toString();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Donate Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _donating
                        ? null
                        : () async {
                            final amount = int.tryParse(amountController.text);
                            if (amount == null || amount < 10) {
                              AppToast.error(
                                context,
                                'Minimum donation is ৳10',
                              );
                              return;
                            }

                            setSheetState(() => _donating = true);

                            final response = await _api.post(
                              '/fundraisers/${widget.fundraiserId}/donate',
                              body: {'amount': amount},
                            );

                            setSheetState(() => _donating = false);

                            if (response.success && mounted) {
                              Navigator.pop(context);
                              AppToast.success(
                                context,
                                'Thank you for your donation!',
                              );
                              _loadFundraiser(); // Refresh
                            } else if (mounted) {
                              AppToast.error(
                                context,
                                response.message ?? 'Donation failed',
                              );
                            }
                          },
                    child: _donating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Donate Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: _buildBody(),
      bottomNavigationBar: _fundraiser != null ? _buildBottomBar() : null,
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFundraiser,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fundraiser == null) {
      return const Center(child: Text('Fundraiser not found'));
    }

    return CustomScrollView(
      slivers: [
        // Cover Image
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _fundraiser!['cover_image_url'] != null
                ? Image.network(
                    _fundraiser!['cover_image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _fundraiser!['title'] ?? 'Fundraiser',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Patient & Hospital
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fundraiser!['patient_name'] ?? '',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    if (_fundraiser!['hospital'] != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _fundraiser!['hospital'],
                          style: TextStyle(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                    children: [
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(AppColors.success),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '৳${_formatAmount(_fundraiser!['amount_raised'] ?? 0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'raised of ৳${_formatAmount(_fundraiser!['amount_needed'] ?? 0)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'of goal',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'About this fundraiser',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fundraiser!['description'] ?? 'No description provided.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                ),

                const SizedBox(height: 120), // Bottom bar space
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.volunteer_activism,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Share Button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  // TODO: Share functionality
                },
              ),
            ),
            const SizedBox(width: 12),

            // Donate Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showDonateSheet,
                  icon: const Icon(Icons.favorite),
                  label: const Text('Donate Now'),
                ),
              ),
            ),
          ],
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
