import 'package:hive/hive.dart';

part 'blood_request.g.dart';

@HiveType(typeId: 0)
class BloodRequest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String requestType; // 'blood_request' or 'donation_offer'

  @HiveField(2)
  final String patientName;

  @HiveField(3)
  final String bloodGroup;

  @HiveField(4)
  final int units;

  @HiveField(5)
  final String hospital;

  @HiveField(6)
  final DateTime requiredDate;

  @HiveField(7)
  final String contactNumber;

  @HiveField(8)
  final String urgency; // 'critical', 'high', 'normal'

  @HiveField(9)
  final String status; // 'active', 'fulfilled', 'closed'

  @HiveField(10)
  final String location;

  @HiveField(11)
  final String userId;

  @HiveField(12)
  final double latitude;

  @HiveField(13)
  final double longitude;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final int? patientAge;

  @HiveField(17)
  final String? alternateContact;

  @HiveField(18)
  final String? notes;

  @HiveField(19)
  final DateTime? updatedAt;

  @HiveField(20)
  final Map<String, dynamic>? locationData; // Store full location object

  BloodRequest({
    required this.id,
    required this.requestType,
    required this.patientName,
    required this.bloodGroup,
    required this.units,
    required this.hospital,
    required this.requiredDate,
    required this.contactNumber,
    required this.urgency,
    required this.status,
    required this.location,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.patientAge,
    this.alternateContact,
    this.notes,
    this.updatedAt,
    this.locationData,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? json['_id'] ?? '',
      requestType: json['request_type'] ?? 'blood_request',
      patientName: json['patient_name'] ?? 'Unknown',
      bloodGroup: json['blood_group'] ?? '',
      units: json['units'] ?? 1,
      hospital: json['hospital'] ?? json['hospital_name'] ?? '',
      requiredDate: DateTime.parse(
        json['required_date'] ?? DateTime.now().toIso8601String(),
      ),
      contactNumber: json['contact_number'] ?? '',
      urgency: json['urgency'] ?? 'normal',
      status: json['status'] ?? 'active',
      location:
          json['address'] ?? json['city'] ?? json['location']?['address'] ?? '',
      userId: json['user_id'] ?? json['requester']?['id'] ?? '',
      latitude:
          (json['latitude'] ??
                  (json['location'] is Map
                      ? json['location']['latitude']
                      : null) ??
                  0.0)
              .toDouble(),
      longitude:
          (json['longitude'] ??
                  (json['location'] is Map
                      ? json['location']['longitude']
                      : null) ??
                  0.0)
              .toDouble(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      patientAge: json['patient_age'] != null
          ? int.tryParse(json['patient_age'].toString())
          : null,
      alternateContact: json['alternate_contact'],
      notes: json['notes'] ?? json['admin_notes'], // Handle admin_notes too
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      locationData: json['location'] is Map<String, dynamic>
          ? json['location']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'request_type': requestType,
      'patient_name': patientName,
      'blood_group': bloodGroup,
      'units': units,
      'hospital_name': hospital,
      'required_date': requiredDate.toIso8601String(),
      'contact_number': contactNumber,
      'urgency': urgency,
      'status': status,
      'location': {
        'address': location,
        'latitude': latitude,
        'longitude': longitude,
        ...?locationData, // helper to merge if exists
      },
      'city': location, // Redundancy for admin panel compatibility
      'address': location, // Redundancy for admin panel compatibility
      'latitude': latitude,
      'longitude': longitude,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'patient_age': patientAge,
      'alternate_contact': alternateContact,
      'notes': notes,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
