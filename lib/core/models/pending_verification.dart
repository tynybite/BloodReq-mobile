import 'package:hive/hive.dart';

part 'pending_verification.g.dart';

@HiveType(typeId: 1)
class PendingVerification extends HiveObject {
  @HiveField(0)
  final String requestId;

  @HiveField(1)
  final String donorId;

  @HiveField(2)
  final String verificationCode;

  @HiveField(3)
  final DateTime timestamp;

  PendingVerification({
    required this.requestId,
    required this.donorId,
    required this.verificationCode,
    required this.timestamp,
  });
}
