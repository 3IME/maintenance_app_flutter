// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collaborateur.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollaborateurAdapter extends TypeAdapter<Collaborateur> {
  @override
  final int typeId = 3;

  @override
  Collaborateur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Collaborateur()
      ..nom = fields[0] as String
      ..prenom = fields[1] as String
      ..fonction = fields[2] as Role;
  }

  @override
  void write(BinaryWriter writer, Collaborateur obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.prenom)
      ..writeByte(2)
      ..write(obj.fonction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborateurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
