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

  @HiveField(14)
  final DateTime createdAt;

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
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['_id'] ?? '',
      requestType: json['request_type'] ?? 'blood_request',
      patientName: json['patient_name'] ?? 'Unknown',
      bloodGroup: json['blood_group'] ?? '',
      units: json['units'] ?? 1,
      hospital: json['hospital_name'] ?? '',
      requiredDate: DateTime.parse(
        json['required_date'] ?? DateTime.now().toIso8601String(),
      ),
      contactNumber: json['contact_number'] ?? '',
      urgency: json['urgency'] ?? 'normal',
      status: json['status'] ?? 'active',
      location: json['location']?['address'] ?? '',
      userId: json['user_id'] ?? '',
      latitude: (json['location']?['latitude'] ?? 0.0).toDouble(),
      longitude: (json['location']?['longitude'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
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
      },
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
