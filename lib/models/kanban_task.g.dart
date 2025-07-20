// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KanbanTaskAdapter extends TypeAdapter<KanbanTask> {
  @override
  final int typeId = 7;

  @override
  KanbanTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KanbanTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dueDate: fields[3] as DateTime,
      status: fields[4] as KanbanStatus,
      colorValue: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, KanbanTask obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KanbanStatusAdapter extends TypeAdapter<KanbanStatus> {
  @override
  final int typeId = 8;

  @override
  KanbanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return KanbanStatus.todo;
      case 1:
        return KanbanStatus.inProgress;
      case 2:
        return KanbanStatus.done;
      default:
        return KanbanStatus.todo;
    }
  }

  @override
  void write(BinaryWriter writer, KanbanStatus obj) {
    switch (obj) {
      case KanbanStatus.todo:
        writer.writeByte(0);
        break;
      case KanbanStatus.inProgress:
        writer.writeByte(1);
        break;
      case KanbanStatus.done:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
