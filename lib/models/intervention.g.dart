// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterventionAdapter extends TypeAdapter<Intervention> {
  @override
  final int typeId = 1;

  @override
  Intervention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Intervention(
      id: fields[0] as String,
      equipmentId: fields[1] as String,
      dateDebut: fields[2] as DateTime,
      dateFin: fields[3] as DateTime,
      type: fields[4] as String,
      cout: fields[5] as double,
      dureeHeures: fields[6] as int,
      urgence: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Intervention obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.equipmentId)
      ..writeByte(2)
      ..write(obj.dateDebut)
      ..writeByte(3)
      ..write(obj.dateFin)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.cout)
      ..writeByte(6)
      ..write(obj.dureeHeures)
      ..writeByte(7)
      ..write(obj.urgence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
