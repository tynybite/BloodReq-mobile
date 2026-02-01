// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BloodRequestAdapter extends TypeAdapter<BloodRequest> {
  @override
  final int typeId = 0;

  @override
  BloodRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BloodRequest(
      id: fields[0] as String,
      requestType: fields[1] as String,
      patientName: fields[2] as String,
      bloodGroup: fields[3] as String,
      units: fields[4] as int,
      hospital: fields[5] as String,
      requiredDate: (fields[6] as DateTime?) ?? DateTime.now(),
      contactNumber: fields[7] as String,
      urgency: fields[8] as String,
      status: fields[9] as String,
      location: fields[10] as String,
      userId: fields[11] as String,
      latitude: fields[12] as double,
      longitude: fields[13] as double,
      createdAt: (fields[15] as DateTime?) ?? DateTime.now(),
      patientAge: fields[16] as int?,
      alternateContact: fields[17] as String?,
      notes: fields[18] as String?,
      updatedAt: fields[19] as DateTime?,
      locationData: (fields[20] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BloodRequest obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.requestType)
      ..writeByte(2)
      ..write(obj.patientName)
      ..writeByte(3)
      ..write(obj.bloodGroup)
      ..writeByte(4)
      ..write(obj.units)
      ..writeByte(5)
      ..write(obj.hospital)
      ..writeByte(6)
      ..write(obj.requiredDate)
      ..writeByte(7)
      ..write(obj.contactNumber)
      ..writeByte(8)
      ..write(obj.urgency)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.userId)
      ..writeByte(12)
      ..write(obj.latitude)
      ..writeByte(13)
      ..write(obj.longitude)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.patientAge)
      ..writeByte(17)
      ..write(obj.alternateContact)
      ..writeByte(18)
      ..write(obj.notes)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.locationData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloodRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
