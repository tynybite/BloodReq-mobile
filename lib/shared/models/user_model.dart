class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String bloodGroup;
  final String? avatarUrl;
  final String country;
  final String city;
  final String? address;
  final String? area;
  final double? latitude;
  final double? longitude;
  final bool isAvailableToDonate;
  final String status;
  final int totalDonations;
  final String? badgeTier;
  final int points;
  final DateTime createdAt;
  final DateTime? lastDonationAt;
  final String? emergencyContact;
  final String? gender; // 'Male', 'Female', 'Other'

  UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.bloodGroup,
    this.avatarUrl,
    required this.country,
    required this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.isAvailableToDonate = true,
    this.status = 'active',
    this.totalDonations = 0,
    this.badgeTier,
    this.points = 0,
    required this.createdAt,
    this.lastDonationAt,
    this.emergencyContact,
    this.address,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bloodGroup: json['blood_group'] as String? ?? 'O+',
      avatarUrl: json['avatar_url'] as String?,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isAvailableToDonate: json['is_available_to_donate'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      totalDonations: json['total_donations'] as int? ?? 0,
      badgeTier: json['badge_tier'] as String?,
      points: json['points'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastDonationAt: json['last_donation_at'] != null
          ? DateTime.parse(json['last_donation_at'] as String)
          : null,
      emergencyContact: json['emergency_contact'] as String?,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'blood_group': bloodGroup,
      'avatar_url': avatarUrl,
      'country': country,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'is_available_to_donate': isAvailableToDonate,
      'status': status,
      'total_donations': totalDonations,
      'badge_tier': badgeTier,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'last_donation_at': lastDonationAt?.toIso8601String(),
      'emergency_contact': emergencyContact,
      'address': address,
      'gender': gender,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? bloodGroup,
    String? avatarUrl,
    String? country,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    bool? isAvailableToDonate,
    String? status,
    int? totalDonations,
    String? badgeTier,
    int? points,
    DateTime? createdAt,
    DateTime? lastDonationAt,
    String? emergencyContact,
    String? address,
    String? gender,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailableToDonate: isAvailableToDonate ?? this.isAvailableToDonate,
      status: status ?? this.status,
      totalDonations: totalDonations ?? this.totalDonations,
      badgeTier: badgeTier ?? this.badgeTier,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      lastDonationAt: lastDonationAt ?? this.lastDonationAt,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      gender: gender ?? this.gender,
    );
  }

  /// Get badge tier based on donation count
  String get calculatedBadgeTier {
    if (totalDonations >= 31) return 'platinum';
    if (totalDonations >= 16) return 'gold';
    if (totalDonations >= 6) return 'silver';
    if (totalDonations >= 1) return 'bronze';
    return 'none';
  }

  /// Get display initials
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
