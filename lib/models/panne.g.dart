// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'panne.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PanneAdapter extends TypeAdapter<Panne> {
  @override
  final int typeId = 2;

  @override
  Panne read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Panne(
      id: fields[0] as String,
      equipmentId: fields[1] as String,
      datePanne: fields[2] as DateTime,
      dateReparation: fields[3] as DateTime?,
      cause: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Panne obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.equipmentId)
      ..writeByte(2)
      ..write(obj.datePanne)
      ..writeByte(3)
      ..write(obj.dateReparation)
      ..writeByte(4)
      ..write(obj.cause);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
