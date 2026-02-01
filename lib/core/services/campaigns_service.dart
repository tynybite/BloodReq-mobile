import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// Campaign model for sponsored promotions
class Campaign {
  final String id;
  final String title;
  final String description;
  final String type;
  final List<CampaignBanner> banners;
  final CampaignSponsor sponsor;
  final CampaignAction action;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final int? daysUntilEnd;

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.banners,
    required this.sponsor,
    required this.action,
    required this.startDate,
    required this.endDate,
    required this.priority,
    this.daysUntilEnd,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'partner_promo',
      banners: (json['banners'] as List? ?? [])
          .map((b) => CampaignBanner.fromJson(b))
          .toList(),
      sponsor: CampaignSponsor.fromJson(json['sponsor'] ?? {}),
      action: CampaignAction.fromJson(json['action'] ?? {}),
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      priority: json['priority'] ?? 0,
      daysUntilEnd: json['days_until_end'],
    );
  }

  bool get isEndingSoon => (daysUntilEnd ?? 999) <= 3;
}

class CampaignBanner {
  final String url;
  final String? altText;
  final int order;

  CampaignBanner({required this.url, this.altText, required this.order});

  factory CampaignBanner.fromJson(Map<String, dynamic> json) {
    return CampaignBanner(
      url: json['url'] ?? '',
      altText: json['alt_text'],
      order: json['order'] ?? 0,
    );
  }
}

class CampaignSponsor {
  final String name;
  final String? logoUrl;
  final String? countryCode;
  final String? contactPhone;

  CampaignSponsor({
    required this.name,
    this.logoUrl,
    this.countryCode,
    this.contactPhone,
  });

  /// Returns the full phone number with country code
  String? get fullPhone {
    if (contactPhone == null || contactPhone!.isEmpty) return null;
    final code = countryCode ?? '+91';
    return '$code$contactPhone';
  }

  factory CampaignSponsor.fromJson(Map<String, dynamic> json) {
    return CampaignSponsor(
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      countryCode: json['country_code'],
      contactPhone: json['contact_phone'],
    );
  }
}

class CampaignAction {
  final String type;
  final String value;
  final String buttonText;

  CampaignAction({
    required this.type,
    required this.value,
    required this.buttonText,
  });

  factory CampaignAction.fromJson(Map<String, dynamic> json) {
    return CampaignAction(
      type: json['type'] ?? 'link',
      value: json['value'] ?? '',
      buttonText: json['button_text'] ?? 'Learn More',
    );
  }
}

/// Campaigns Service for fetching and tracking sponsored campaigns
class CampaignsService {
  static final CampaignsService _instance = CampaignsService._internal();
  factory CampaignsService() => _instance;
  CampaignsService._internal();

  final ApiService _api = ApiService();

  /// Fetch active campaigns for a given city
  Future<List<Campaign>> getCampaigns({String? city, int limit = 5}) async {
    try {
      String url = ApiEndpoints.campaigns;
      final params = <String, String>{};
      if (city != null) params['city'] = city;
      params['limit'] = limit.toString();

      if (params.isNotEmpty) {
        url =
            '$url?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }

      final response = await _api.get<Map<String, dynamic>>(url);

      if (response.success && response.data != null) {
        final campaignsList = response.data!['campaigns'] as List? ?? [];
        return campaignsList.map((c) => Campaign.fromJson(c)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('CampaignsService.getCampaigns error: $e');
      return [];
    }
  }

  /// Track a view or click on a campaign
  Future<bool> trackCampaign(
    String campaignId, {
    required String action,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.campaignTrack(campaignId),
        body: {'action': action},
      );
      return response.success;
    } catch (e) {
      debugPrint('CampaignsService.trackCampaign error: $e');
      return false;
    }
  }

  /// Track view
  Future<void> trackView(String campaignId) async {
    await trackCampaign(campaignId, action: 'view');
  }

  /// Track click
  Future<void> trackClick(String campaignId) async {
    await trackCampaign(campaignId, action: 'click');
  }
}
