import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../core/providers/language_provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _request;
  bool _isLoading = true;
  String? _error;
  bool _offering = false;
  String? _distance;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<Map<String, dynamic>>(
      '/blood-requests/${widget.requestId}',
    );

    if (response.success && response.data != null) {
      setState(() => _request = response.data as Map<String, dynamic>);
      _calculateDistance();
    } else {
      setState(() => _error = response.message ?? 'Failed to load request');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _calculateDistance() async {
    if (_request == null ||
        _request!['latitude'] == null ||
        _request!['longitude'] == null) {
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        (_request!['latitude'] as num).toDouble(),
        (_request!['longitude'] as num).toDouble(),
      );

      setState(() {
        _distance = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
      });
    } catch (e) {
      debugPrint('Error calculating distance: $e');
    }
  }

  Future<void> _offerToDonate(LanguageProvider lang) async {
    setState(() => _offering = true);

    final response = await _api.post(
      '/blood-requests/${widget.requestId}/donate',
      body: {}, // API requires a JSON body even if empty
    );

    setState(() => _offering = false);

    if (!mounted) return;

    if (response.success) {
      AppToast.success(context, lang.getText('toast_offer_success'));
      _loadRequest();
    } else {
      final message = response.message ?? lang.getText('toast_offer_failed');
      if (message.toLowerCase().contains('cannot') ||
          message.toLowerCase().contains('forbidden')) {
        AppToast.warning(context, message);
      } else {
        AppToast.error(context, message);
      }
    }
  }

  Color get urgencyColor {
    switch (_request?['urgency']) {
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
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: context.scaffoldBg,
          appBar: AppBar(
            title: Text(lang.getText('request_details_title')),
            backgroundColor: context.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (_request != null)
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    final shareText = lang
                        .getText('share_text')
                        .replaceAll('{group}', _request!['blood_group'] ?? '')
                        .replaceAll('{name}', _request!['patient_name'] ?? '')
                        .replaceAll('{hospital}', _request!['hospital'] ?? '')
                        .replaceAll(
                          '{contact}',
                          _request!['contact_number'] ?? '',
                        );
                    Share.share(shareText);
                  },
                ),
            ],
          ),
          body: _buildBody(lang),
          bottomNavigationBar: _request != null ? _buildBottomBar(lang) : null,
        );
      },
    );
  }

  Widget _buildBody(LanguageProvider lang) {
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
                onPressed: _loadRequest,
                child: Text(lang.getText('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_request == null) {
      return Center(child: Text(lang.getText('no_requests_found')));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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
            child: Row(
              children: [
                // Blood Group
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _request!['blood_group'] ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _request!['patient_name'] ?? lang.getText('patient'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (_request!['urgency'] ?? 'planned')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_request!['units'] ?? 1} ${(_request!['units'] ?? 1) > 1 ? lang.getText('units') : lang.getText('unit')} ${lang.getText('needed')}',
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
          const SizedBox(height: 20),

          // Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.local_hospital_outlined,
                  label: lang.getText('hospital'),
                  value: _request!['hospital'] ?? lang.getText('not_specified'),
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: lang.getText('location'),
                  value: _request!['city'] ?? lang.getText('not_specified'),
                  extras: _distance != null
                      ? '${lang.getText('approx')} $_distance ${lang.getText('away')}'
                      : null,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: lang.getText('contact'),
                  value:
                      _request!['contact_number'] ??
                      lang.getText('not_available'),
                  isPhone: true,
                  onTap: () async {
                    final phone = _request!['contact_number'];
                    if (phone != null) {
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
                if (_request!['notes'] != null &&
                    _request!['notes'].toString().isNotEmpty) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: lang.getText('notes'),
                    value: _request!['notes'],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Donor Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_request!['donor_count'] ?? 0} ${lang.getText('donors_count')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        lang.getText('offered_to_help'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomBar(LanguageProvider lang) {
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
            // Call Button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(Icons.phone, color: AppColors.success),
                onPressed: () async {
                  final phone = _request!['contact_number'];
                  if (phone != null) {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            // Directions Button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(Icons.directions, color: AppColors.info),
                onPressed: () async {
                  final lat = _request!['latitude'];
                  final lng = _request!['longitude'];

                  if (lat != null && lng != null) {
                    final uri = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } else {
                    // Fallback to searching by hospital name + city
                    final query = Uri.encodeComponent(
                      '${_request!['hospital']}, ${_request!['city']}',
                    );
                    final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$query',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            // Donate Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _offering ? null : () => _offerToDonate(lang),
                  child: _offering
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(lang.getText('offer_to_donate')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? extras; // Added for distance info
  final bool isPhone;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.extras,
    this.isPhone = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isPhone ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (extras != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      extras!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isPhone)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}
