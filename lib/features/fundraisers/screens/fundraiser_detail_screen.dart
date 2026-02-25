import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/bkash_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../core/providers/language_provider.dart';

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
      if (!mounted) return;
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(
        () => _error =
            response.message ?? lang.getText('load_fundraisers_failed'),
      );
    }

    setState(() => _isLoading = false);
  }

  double get progress {
    final raised = (_fundraiser?['amount_raised'] ?? 0).toDouble();
    final needed = (_fundraiser?['amount_needed'] ?? 1).toDouble();
    return (raised / needed).clamp(0.0, 1.0);
  }

  Future<void> _showDonateSheet() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Pre-fetch exchange rate
    double bdtPerUsd = 110.0;
    final rateRes = await _api.get<dynamic>('/payments/exchange-rate');
    if (rateRes.success && rateRes.data != null) {
      final rateData = rateRes.data as Map<String, dynamic>;
      bdtPerUsd = (rateData['bdt_per_usd'] ?? 110.0).toDouble();
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => _DonateSheet(
        fundraiserId: widget.fundraiserId,
        fundraiserTitle: _fundraiser?['title'] ?? '',
        bdtPerUsd: bdtPerUsd,
        onSuccess: () {
          if (mounted) {
            AppToast.success(context, lang.getText('donation_success'));
            _loadFundraiser();
          }
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
    final lang = Provider.of<LanguageProvider>(context);

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
                child: Text(lang.getText('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_fundraiser == null) {
      return Center(child: Text(lang.getText('no_fundraisers')));
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
                  _fundraiser!['title'] ??
                      lang.getText('fundraiser_default_title'),
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
                                '${getCurrencySymbol(context)}${_formatAmount(_fundraiser!['amount_raised'] ?? 0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                '${lang.getText('raised_of')} ${getCurrencySymbol(context)}${_formatAmount(_fundraiser!['amount_needed'] ?? 0)}',
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
                                lang.getText('of_goal'),
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
                  lang.getText('about_fundraiser'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fundraiser!['description'] ?? lang.getText('no_description'),
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);

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
                  Share.share(
                    'Support this fundraiser: ${_fundraiser!['title']}\n'
                    'Goal: ${getCurrencySymbol(context)}${_fundraiser!['amount_needed']}\n'
                    'Raised: ${getCurrencySymbol(context)}${_fundraiser!['amount_raised']}\n\n'
                    'Read more and donate on BloodReq!',
                  );
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
                  label: Text(lang.getText('donate_now')),
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

// ─────────────────────────────────────────────────────────────────────────────
// Separate StatefulWidget for the donate bottom sheet
// (keeps the parent clean and avoids StatefulBuilder complexity)
// ─────────────────────────────────────────────────────────────────────────────

enum _PayCurrency { bdt, usd }

class _DonateSheet extends StatefulWidget {
  final String fundraiserId;
  final String fundraiserTitle;
  final double bdtPerUsd;
  final VoidCallback onSuccess;

  const _DonateSheet({
    required this.fundraiserId,
    required this.fundraiserTitle,
    required this.bdtPerUsd,
    required this.onSuccess,
  });

  @override
  State<_DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<_DonateSheet> {
  final _amountController = TextEditingController();
  _PayCurrency _currency = _PayCurrency.bdt;
  bool _paying = false;

  // Preset amounts per currency
  static const _bdtPresets = [100, 500, 1000, 5000];
  static const _usdPresets = [1, 5, 10, 50];

  bool get _isBdt => _currency == _PayCurrency.bdt;

  String get _symbol => _isBdt ? '৳' : '\$';

  /// Converted equivalent shown below the text field
  String get _convertedLabel {
    final input = double.tryParse(_amountController.text);
    if (input == null || input <= 0) return '';
    if (_isBdt) {
      final usd = input / widget.bdtPerUsd;
      return '≈ \$${usd.toStringAsFixed(2)} USD';
    } else {
      final bdt = input * widget.bdtPerUsd;
      return '≈ ৳${bdt.toStringAsFixed(0)} BDT';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final raw = double.tryParse(_amountController.text);
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _paying = true);

    try {
      bool success;

      if (_isBdt) {
        final amountBdt = raw.round();
        if (amountBdt < 10) throw Exception('Minimum donation is ৳10');
        success = await BkashService().donateTo(
          fundraiserId: widget.fundraiserId,
          amountBdt: amountBdt,
          context: context,
        );
      } else {
        if (raw < 0.5) throw Exception('Minimum donation is \$0.50');
        success = await StripeService().donateTo(
          fundraiserId: widget.fundraiserId,
          amount: raw, // dollars — StripeService sends as-is to backend
          context: context,
        );
      }

      if (!mounted) return;
      setState(() => _paying = false);

      if (success) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _isBdt ? _bdtPresets : _usdPresets;

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
          // ── Header ──────────────────────────────────────────────────────────
          Text(
            'Donate to Fundraiser',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.fundraiserTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.fundraiserTitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 20),

          // ── Currency toggle ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _CurrencyTab(
                  label: '৳ BDT',
                  sublabel: 'bKash',
                  color: const Color(0xFFE2166E),
                  selected: _isBdt,
                  onTap: () {
                    setState(() {
                      _currency = _PayCurrency.bdt;
                      _amountController.clear();
                    });
                  },
                ),
                _CurrencyTab(
                  label: '\$ USD',
                  sublabel: 'Stripe',
                  color: const Color(0xFF635BFF),
                  selected: !_isBdt,
                  onTap: () {
                    setState(() {
                      _currency = _PayCurrency.usd;
                      _amountController.clear();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Amount field ─────────────────────────────────────────────────────
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountController,
            builder: (context, value, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount ($_symbol)',
                    prefixText: '$_symbol ',
                    hintText: _isBdt ? '500' : '5.00',
                  ),
                  autofocus: true,
                ),
                if (_convertedLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _convertedLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Quick-amount chips ───────────────────────────────────────────────
          Wrap(
            spacing: 8,
            children: presets.map((p) {
              final label = _isBdt ? '৳$p' : '\$$p';
              final color = _isBdt
                  ? const Color(0xFFE2166E)
                  : const Color(0xFF635BFF);
              return ActionChip(
                label: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                onPressed: () =>
                    setState(() => _amountController.text = p.toString()),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Pay button ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBdt
                    ? const Color(0xFFE2166E)
                    : const Color(0xFF635BFF),
                foregroundColor: Colors.white,
              ),
              onPressed: _paying ? null : _pay,
              child: _paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isBdt ? Icons.phone_android : Icons.credit_card,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isBdt ? 'Pay with bKash' : 'Pay with Stripe',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CurrencyTab({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
