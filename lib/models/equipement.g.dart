// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipementAdapter extends TypeAdapter<Equipement> {
  @override
  final int typeId = 0;

  @override
  Equipement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Equipement(
      id: fields[0] as String,
      nom: fields[1] as String,
      type: fields[2] as String,
      dateMiseEnService: fields[3] as DateTime,
    )
      ..interventions = (fields[4] as HiveList?)?.castHiveList()
      ..pannes = (fields[5] as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, Equipement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.dateMiseEnService)
      ..writeByte(4)
      ..write(obj.interventions)
      ..writeByte(5)
      ..write(obj.pannes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
