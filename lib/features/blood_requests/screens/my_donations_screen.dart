import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'donation_receipt_sheet.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _bloodDonations = [];
  List<Map<String, dynamic>> _paymentDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadBloodDonations(), _loadPaymentDonations()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadBloodDonations() async {
    final response = await _api.get<dynamic>('/blood-donations/my');
    if (response.success && response.data != null) {
      List<dynamic> list;
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map) {
        final m = response.data as Map<String, dynamic>;
        list = (m['data'] ?? m['donations'] ?? []) as List;
      } else {
        list = [];
      }
      if (mounted) {
        setState(
          () => _bloodDonations = list
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        );
      }
    }
  }

  Future<void> _loadPaymentDonations() async {
    final response = await _api.get<dynamic>('/donations/my');
    if (response.success && response.data != null) {
      List<dynamic> list;
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map) {
        final m = response.data as Map<String, dynamic>;
        list = (m['donations'] ?? m['data'] ?? []) as List;
      } else {
        list = [];
      }
      if (mounted) {
        setState(
          () => _paymentDonations = list
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        );
      }
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
        return AppColors.success;
      case 'offered':
      case 'accepted':
        return AppColors.warning;
      case 'cancelled':
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'offered':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.handshake_outlined;
      default:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Donations'),
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Blood Offers',
              icon: Icon(Icons.bloodtype_outlined, size: 18),
            ),
            Tab(
              text: 'Payments',
              icon: Icon(Icons.payments_outlined, size: 18),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BloodDonationsList(
                    donations: _bloodDonations,
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                  ),
                  _PaymentDonationsList(donations: _paymentDonations),
                ],
              ),
            ),
    );
  }
}

// ─── Blood Offers Tab ─────────────────────────────────────────────────────────

class _BloodDonationsList extends StatelessWidget {
  final List<Map<String, dynamic>> donations;
  final Color Function(String?) statusColor;
  final IconData Function(String?) statusIcon;

  const _BloodDonationsList({
    required this.donations,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No blood donation offers yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (ctx, i) {
        final d = donations[i];
        return _BloodDonationCard(
              donation: d,
              statusColor: statusColor(d['status']),
              statusIcon: statusIcon(d['status']),
            )
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn()
            .slideY(begin: 0.1);
      },
    );
  }
}

// ─── Payment Donations Tab ────────────────────────────────────────────────────

class _PaymentDonationsList extends StatelessWidget {
  final List<Map<String, dynamic>> donations;

  const _PaymentDonationsList({required this.donations});

  String _fmt(dynamic amount, String currency) {
    final n = (amount ?? 0).toDouble();
    final sym = currency == 'USD' ? '\$' : '৳';
    return '$sym${n.toStringAsFixed(currency == 'USD' ? 2 : 0)}';
  }

  String _fmtDate(String? s) {
    if (s == null) return '';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No fundraiser donations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Donate to a fundraiser to see it here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (ctx, i) {
        final d = donations[i];
        final currency = (d['currency'] ?? 'BDT') as String;
        final method = (d['payment_method'] ?? '') as String;
        final isBkash = method == 'bkash';
        final methodColor = isBkash
            ? const Color(0xFFE2166E)
            : const Color(0xFF635BFF);

        return GestureDetector(
              onTap: () => DonationReceiptSheet.show(ctx, d),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ctx.cardBg,
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
                    // Payment method icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: methodColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isBkash ? Icons.phone_android : Icons.credit_card,
                        color: methodColor,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Fundraiser title + method/date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['fundraiser_title']?.toString().isNotEmpty == true
                                ? d['fundraiser_title'].toString()
                                : 'Fundraiser Donation',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${method.isNotEmpty ? method[0].toUpperCase() + method.substring(1) : 'Payment'}'
                            ' • ${_fmtDate(d['created_at']?.toString())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount + status badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(d['amount'], currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (d['status'] ?? 'completed')
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), // Container
            ) // GestureDetector
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn()
            .slideY(begin: 0.1);
      },
    );
  }
}

// ─── Blood Donation Card ──────────────────────────────────────────────────────

class _BloodDonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final Color statusColor;
  final IconData statusIcon;

  const _BloodDonationCard({
    required this.donation,
    required this.statusColor,
    required this.statusIcon,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = donation['blood_request'] ?? donation['request'] ?? {};

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['patient_name'] ?? 'Blood Request',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request['blood_group'] ?? '—',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            request['hospital'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (donation['status'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(donation['created_at']?.toString()),
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              if (donation['message'] != null &&
                  donation['message'].toString().isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.message_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    donation['message'].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (donation['status'] == 'offered' ||
              donation['status'] == 'accepted')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final requestId =
                        request['id'] ??
                        request['_id'] ??
                        donation['request_id'];
                    if (requestId != null) {
                      context.push('/verify/$requestId', extra: false);
                    }
                  },
                  icon: const Icon(Icons.pin),
                  label: const Text('Enter Verification Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
