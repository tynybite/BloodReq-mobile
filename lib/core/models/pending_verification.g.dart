// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_verification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingVerificationAdapter extends TypeAdapter<PendingVerification> {
  @override
  final int typeId = 1;

  @override
  PendingVerification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingVerification(
      requestId: fields[0] as String,
      donorId: fields[1] as String,
      verificationCode: fields[2] as String,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PendingVerification obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.requestId)
      ..writeByte(1)
      ..write(obj.donorId)
      ..writeByte(2)
      ..write(obj.verificationCode)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingVerificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
